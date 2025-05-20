import React from 'react';
import { 
  Box, 
  Typography, 
  Paper, 
  Grid, 
  TextField, 
  Button, 
  Divider,
  Avatar
} from '@mui/material';
import { Person as PersonIcon } from '@mui/icons-material';
import { useAuth } from '../context/AuthContext';

const Profile = () => {
  const { user } = useAuth();

  return (
    <Box>
      <Typography variant="h4" component="h1" gutterBottom>
        Profile
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        View and manage your account information
      </Typography>

      <Grid container spacing={4}>
        {/* User Info Card */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
              <Avatar sx={{ bgcolor: 'primary.main', mr: 2 }}>
                <PersonIcon />
              </Avatar>
              <Typography variant="h5" component="h2">
                User Information
              </Typography>
            </Box>
            
            <Divider sx={{ mb: 3 }} />
            
            <Grid container spacing={2}>
              <Grid item xs={12} sm={4}>
                <Typography variant="subtitle2" color="text.secondary">
                  Username
                </Typography>
              </Grid>
              <Grid item xs={12} sm={8}>
                <Typography variant="body1">
                  {user?.username || 'N/A'}
                </Typography>
              </Grid>
              
              <Grid item xs={12} sm={4}>
                <Typography variant="subtitle2" color="text.secondary">
                  Email
                </Typography>
              </Grid>
              <Grid item xs={12} sm={8}>
                <Typography variant="body1">
                  {user?.email || 'N/A'}
                </Typography>
              </Grid>
              
              <Grid item xs={12} sm={4}>
                <Typography variant="subtitle2" color="text.secondary">
                  User ID
                </Typography>
              </Grid>
              <Grid item xs={12} sm={8}>
                <Typography variant="body1">
                  {user?.id || 'N/A'}
                </Typography>
              </Grid>
              
              <Grid item xs={12} sm={4}>
                <Typography variant="subtitle2" color="text.secondary">
                  Status
                </Typography>
              </Grid>
              <Grid item xs={12} sm={8}>
                <Typography 
                  variant="body1" 
                  sx={{ 
                    color: user?.is_active ? 'success.main' : 'error.main',
                    fontWeight: 'medium'
                  }}
                >
                  {user?.is_active ? 'Active' : 'Inactive'}
                </Typography>
              </Grid>
            </Grid>
          </Paper>
        </Grid>

        {/* Change Password Card */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h5" component="h2" gutterBottom>
              Change Password
            </Typography>
            
            <Divider sx={{ mb: 3 }} />
            
            <Box component="form">
              <TextField
                margin="normal"
                required
                fullWidth
                name="currentPassword"
                label="Current Password"
                type="password"
                id="currentPassword"
              />
              
              <TextField
                margin="normal"
                required
                fullWidth
                name="newPassword"
                label="New Password"
                type="password"
                id="newPassword"
              />
              
              <TextField
                margin="normal"
                required
                fullWidth
                name="confirmPassword"
                label="Confirm New Password"
                type="password"
                id="confirmPassword"
              />
              
              <Button
                type="submit"
                variant="contained"
                sx={{ mt: 3 }}
              >
                Update Password
              </Button>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Profile;
