const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Function to execute shell commands
function exec(command) {
  try {
    console.log(`Executing: ${command}`);
    execSync(command, { stdio: 'inherit' });
    return true;
  } catch (error) {
    console.error(`Error executing command: ${command}`);
    console.error(error.message);
    return false;
  }
}

// Main function
async function main() {
  console.log('Deploying CORS proxy to Render...');

  // Check if git is installed
  try {
    execSync('git --version', { stdio: 'ignore' });
  } catch (error) {
    console.error('Error: Git is not installed or not in PATH.');
    process.exit(1);
  }

  // Create a new repository for the CORS proxy
  const repoName = 'envirosense-cors-proxy';
  const repoPath = path.join(__dirname, repoName);

  // Check if the repository already exists
  if (fs.existsSync(repoPath)) {
    console.log(`Repository ${repoName} already exists. Removing it...`);
    fs.rmSync(repoPath, { recursive: true, force: true });
  }

  // Create the repository directory
  fs.mkdirSync(repoPath);

  // Copy the CORS proxy files to the repository
  fs.copyFileSync(path.join(__dirname, 'cors-proxy', 'package.json'), path.join(repoPath, 'package.json'));
  fs.copyFileSync(path.join(__dirname, 'cors-proxy', 'index.js'), path.join(repoPath, 'index.js'));
  fs.copyFileSync(path.join(__dirname, 'cors-proxy', 'README.md'), path.join(repoPath, 'README.md'));
  fs.copyFileSync(path.join(__dirname, 'cors-proxy', '.gitignore'), path.join(repoPath, '.gitignore'));
  fs.copyFileSync(path.join(__dirname, 'cors-proxy', 'render.yaml'), path.join(repoPath, 'render.yaml'));

  // Initialize git repository
  process.chdir(repoPath);
  if (!exec('git init')) {
    console.error('Error initializing git repository.');
    process.exit(1);
  }

  // Add files to git
  if (!exec('git add .')) {
    console.error('Error adding files to git.');
    process.exit(1);
  }

  // Commit files
  if (!exec('git commit -m "Initial commit"')) {
    console.error('Error committing files.');
    process.exit(1);
  }

  // Instructions for manual deployment
  console.log('\nCORS proxy files prepared for deployment.');
  console.log('\nTo deploy to Render:');
  console.log('1. Create a new GitHub repository named "envirosense-cors-proxy"');
  console.log('2. Push the local repository to GitHub:');
  console.log(`   cd ${repoPath}`);
  console.log('   git remote add origin https://github.com/YOUR_USERNAME/envirosense-cors-proxy.git');
  console.log('   git push -u origin main');
  console.log('3. Create a new Web Service on Render:');
  console.log('   - Connect your GitHub repository');
  console.log('   - Set the build command to: npm install');
  console.log('   - Set the start command to: npm start');
  console.log('4. After deployment, update the REACT_APP_API_URL in web/.env.proxy with your Render URL');
  console.log('5. Run node update_web_for_proxy.js to update the web application');
  console.log('6. Rebuild and redeploy the web application');
}

main().catch(error => {
  console.error('Error:', error);
  process.exit(1);
});
