import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  TextField,
  Button,
  Divider,
  Avatar,
  Alert,
  Snackbar,
  CircularProgress,
  useMediaQuery,
  useTheme
} from '@mui/material';
import {
  Person as PersonIcon,
  Save as SaveIcon,
  Edit as EditIcon
} from '@mui/icons-material';
import { useAuth } from '../context/AuthContext';

const Profile = () => {
  const { user, updateProfile } = useAuth();
  const theme = useTheme();
  const isXsScreen = useMediaQuery(theme.breakpoints.down('sm'));

  // State for profile form
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [editMode, setEditMode] = useState(false);

  // State for password form
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [passwordError, setPasswordError] = useState('');

  // State for notifications
  const [notification, setNotification] = useState({ open: false, message: '', severity: 'success' });
  const [updating, setUpdating] = useState(false);

  // Initialize form with user data
  useEffect(() => {
    if (user) {
      setUsername(user.username || '');
      setEmail(user.email || '');
    }
  }, [user]);

  // Handle profile update
  const handleProfileUpdate = async (e) => {
    e.preventDefault();

    // Validate form
    if (!username.trim() || !email.trim()) {
      setNotification({
        open: true,
        message: 'Please fill in all fields',
        severity: 'error'
      });
      return;
    }

    setUpdating(true);

    try {
      await updateProfile({ username, email });
      setEditMode(false);
      setNotification({
        open: true,
        message: 'Profile updated successfully',
        severity: 'success'
      });
    } catch (error) {
      setNotification({
        open: true,
        message: error.response?.data?.detail || 'Failed to update profile',
        severity: 'error'
      });
    } finally {
      setUpdating(false);
    }
  };

  // Handle password change
  const handlePasswordChange = async (e) => {
    e.preventDefault();

    // Validate form
    if (!currentPassword || !newPassword || !confirmPassword) {
      setPasswordError('Please fill in all password fields');
      return;
    }

    if (newPassword !== confirmPassword) {
      setPasswordError('New passwords do not match');
      return;
    }

    if (newPassword.length < 8) {
      setPasswordError('Password must be at least 8 characters long');
      return;
    }

    setPasswordError('');
    setUpdating(true);

    try {
      // Direct API call instead of using the context function
      // This helps bypass any potential issues in the context implementation
      const token = localStorage.getItem('token');
      const apiUrl = process.env.REACT_APP_API_URL || 'https://envirosense-2khv.onrender.com/api/v1';
      const response = await fetch(`${apiUrl}/auth/change-password`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          current_password: currentPassword,
          new_password: newPassword
        })
      });

      const data = await response.json();
      console.log('Password change response:', response.status, data);

      if (!response.ok) {
        throw new Error(data.detail || 'Failed to change password');
      }

      // Clear form
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');

      setNotification({
        open: true,
        message: 'Password changed successfully',
        severity: 'success'
      });
    } catch (error) {
      console.error('Password change failed:', error);

      setPasswordError(error.message || 'Failed to change password. Please try again.');
      setNotification({
        open: true,
        message: error.message || 'Failed to change password. Please try again.',
        severity: 'error'
      });
    } finally {
      setUpdating(false);
    }
  };

  // Handle notification close
  const handleNotificationClose = () => {
    setNotification({ ...notification, open: false });
  };

  return (
    <Box>
      <Typography variant="h4" component="h1" gutterBottom>
        Profile
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        View and manage your account information
      </Typography>

      {/* Notification */}
      <Snackbar
        open={notification.open}
        autoHideDuration={6000}
        onClose={handleNotificationClose}
        anchorOrigin={{ vertical: 'top', horizontal: 'center' }}
      >
        <Alert
          onClose={handleNotificationClose}
          severity={notification.severity}
          variant="filled"
          sx={{ width: '100%' }}
        >
          {notification.message}
        </Alert>
      </Snackbar>

      <Grid container spacing={4}>
        {/* User Info Card */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Box sx={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              mb: 3,
              flexDirection: isXsScreen ? 'column' : 'row',
              gap: isXsScreen ? 2 : 0
            }}>
              <Box sx={{
                display: 'flex',
                alignItems: 'center',
                width: isXsScreen ? '100%' : 'auto'
              }}>
                <Avatar sx={{ bgcolor: 'primary.main', mr: 2 }}>
                  <PersonIcon />
                </Avatar>
                <Typography variant="h5" component="h2">
                  User Information
                </Typography>
              </Box>

              <Button
                variant={editMode ? "contained" : "outlined"}
                color={editMode ? "primary" : "secondary"}
                startIcon={editMode ? <SaveIcon /> : <EditIcon />}
                onClick={() => editMode ? handleProfileUpdate() : setEditMode(true)}
                disabled={updating}
                sx={{ minWidth: 120 }}
              >
                {updating ? <CircularProgress size={24} /> : (editMode ? 'Save' : 'Edit')}
              </Button>
            </Box>

            <Divider sx={{ mb: 3 }} />

            {editMode ? (
              <Box component="form" onSubmit={handleProfileUpdate}>
                <Grid container spacing={2}>
                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Username"
                      value={username}
                      onChange={(e) => setUsername(e.target.value)}
                      margin="normal"
                      required
                    />
                  </Grid>

                  <Grid item xs={12}>
                    <TextField
                      fullWidth
                      label="Email"
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      margin="normal"
                      required
                    />
                  </Grid>

                  <Grid item xs={12} sx={{ mt: 2 }}>
                    <Button
                      type="submit"
                      variant="contained"
                      color="primary"
                      fullWidth
                      disabled={updating}
                    >
                      {updating ? <CircularProgress size={24} /> : 'Update Profile'}
                    </Button>

                    <Button
                      variant="outlined"
                      color="secondary"
                      fullWidth
                      onClick={() => {
                        setEditMode(false);
                        // Reset form to original values
                        setUsername(user?.username || '');
                        setEmail(user?.email || '');
                      }}
                      disabled={updating}
                      sx={{ mt: 1 }}
                    >
                      Cancel
                    </Button>
                  </Grid>
                </Grid>
              </Box>
            ) : (
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
            )}
          </Paper>
        </Grid>

        {/* Change Password Card */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h5" component="h2" gutterBottom>
              Change Password
            </Typography>

            <Divider sx={{ mb: 3 }} />

            <Box component="form" onSubmit={handlePasswordChange}>
              {passwordError && (
                <Alert severity="error" sx={{ mb: 2 }}>
                  {passwordError}
                </Alert>
              )}

              <TextField
                margin="normal"
                required
                fullWidth
                name="currentPassword"
                label="Current Password"
                type="password"
                id="currentPassword"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                disabled={updating}
              />

              <TextField
                margin="normal"
                required
                fullWidth
                name="newPassword"
                label="New Password"
                type="password"
                id="newPassword"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                disabled={updating}
                helperText="Password must be at least 8 characters long"
              />

              <TextField
                margin="normal"
                required
                fullWidth
                name="confirmPassword"
                label="Confirm New Password"
                type="password"
                id="confirmPassword"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                disabled={updating}
                error={newPassword !== confirmPassword && confirmPassword !== ''}
                helperText={
                  newPassword !== confirmPassword && confirmPassword !== ''
                    ? 'Passwords do not match'
                    : ''
                }
              />

              <Button
                type="submit"
                variant="contained"
                sx={{ mt: 3 }}
                disabled={updating}
                fullWidth
              >
                {updating ? <CircularProgress size={24} /> : 'Update Password'}
              </Button>

              <Typography
                variant="body2"
                color="text.secondary"
                sx={{ mt: 2, textAlign: 'center' }}
              >
                Having trouble? Make sure your current password is correct.
              </Typography>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Profile;
