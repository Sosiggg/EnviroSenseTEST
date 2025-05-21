import { useState, useEffect } from 'react';
import {
  Box,
  Chip,
  Tooltip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Alert,
  CircularProgress,
  alpha,
  useTheme
} from '@mui/material';
import {
  WifiTethering as WifiIcon,
  WifiOff as WifiOffIcon,
  Refresh as RefreshIcon,
  // ErrorIcon is imported but not used
  Info as InfoIcon
} from '@mui/icons-material';
import websocketManager from '../utils/websocket';
import { useSensor } from '../context/SensorContext';

// WebSocket status indicator component
const WebSocketStatus = () => {
  const theme = useTheme();
  const { isConnected, error } = useSensor();
  const [statusDetails, setStatusDetails] = useState({});
  const [dialogOpen, setDialogOpen] = useState(false);
  const [reconnecting, setReconnecting] = useState(false);

  // Update status details when connection status changes
  useEffect(() => {
    const updateStatus = () => {
      setStatusDetails(websocketManager.getStatus());
    };

    // Initial status update
    updateStatus();

    // Add listener for connection status changes
    const removeListener = websocketManager.addListener((data) => {
      if (data.type === 'connection') {
        updateStatus();

        // Auto-close reconnecting state after successful connection
        if (data.status === 'connected' && reconnecting) {
          setReconnecting(false);
        }
      }
    });

    // Cleanup
    return () => {
      removeListener();
    };
  }, [reconnecting]);

  // Handle manual reconnect
  const handleReconnect = () => {
    setReconnecting(true);
    websocketManager.forceReconnect();
  };

  // Get status color
  const getStatusColor = () => {
    if (isConnected) return 'success';
    if (statusDetails.status === 'connecting' || statusDetails.status === 'reconnecting') return 'warning';
    return 'error';
  };

  // Get status icon
  const getStatusIcon = () => {
    if (isConnected) return <WifiIcon fontSize="small" />;
    if (statusDetails.status === 'connecting' || statusDetails.status === 'reconnecting') {
      return (
        <Box sx={{ display: 'flex', alignItems: 'center' }}>
          <CircularProgress size={14} thickness={4} sx={{ mr: 0.5 }} />
          <WifiIcon fontSize="small" />
        </Box>
      );
    }
    return <WifiOffIcon fontSize="small" />;
  };

  // Get status text
  const getStatusText = () => {
    if (isConnected) return 'Connected';
    if (statusDetails.status === 'connecting') return 'Connecting...';
    if (statusDetails.status === 'reconnecting') {
      return `Reconnecting (${statusDetails.reconnectAttempts}/${statusDetails.maxReconnectAttempts})`;
    }
    if (statusDetails.status === 'timeout') return 'Connection Timeout';
    if (statusDetails.status === 'error') return 'Connection Error';
    if (statusDetails.status === 'failed') return 'Connection Failed';
    return 'Disconnected';
  };

  // Get tooltip text
  const getTooltipText = () => {
    if (isConnected) return 'WebSocket connected - receiving real-time data';
    if (statusDetails.status === 'connecting') return 'Establishing WebSocket connection...';
    if (statusDetails.status === 'reconnecting') {
      return `Attempting to reconnect (${statusDetails.reconnectAttempts}/${statusDetails.maxReconnectAttempts})`;
    }
    if (statusDetails.lastError) return `Connection issue: ${statusDetails.lastError}`;
    return 'WebSocket disconnected - click to reconnect';
  };

  return (
    <>
      <Box sx={{ display: 'flex', alignItems: 'center' }}>
        <Tooltip title={getTooltipText()}>
          <Chip
            icon={getStatusIcon()}
            label={getStatusText()}
            color={getStatusColor()}
            size="small"
            variant="outlined"
            onClick={() => setDialogOpen(true)}
            sx={{
              height: 32,
              borderRadius: 4,
              cursor: 'pointer',
              borderWidth: 1.5,
              pl: 0.5,
              '& .MuiChip-icon': {
                animation: isConnected ? 'pulse 2s infinite' : 'none',
                ml: 0.5,
              },
              '& .MuiChip-label': {
                px: 1.5,
                fontWeight: 'medium',
                fontSize: '0.8rem'
              },
              '@keyframes pulse': {
                '0%': { opacity: 0.6 },
                '50%': { opacity: 1 },
                '100%': { opacity: 0.6 }
              },
              boxShadow: isConnected ? `0 0 8px ${alpha(theme.palette.success.main, 0.4)}` : 'none',
              transition: 'all 0.3s ease'
            }}
          />
        </Tooltip>

        {!isConnected && (
          <Tooltip title="Reconnect WebSocket">
            <IconButton
              size="small"
              color="primary"
              onClick={handleReconnect}
              disabled={reconnecting}
              sx={{
                ml: 1.5,
                border: '1px solid',
                borderColor: 'divider',
                '&:hover': {
                  backgroundColor: alpha(theme.palette.primary.main, 0.1)
                }
              }}
            >
              <RefreshIcon fontSize="small" sx={{
                animation: reconnecting ? 'spin 1.5s linear infinite' : 'none',
                '@keyframes spin': {
                  '0%': { transform: 'rotate(0deg)' },
                  '100%': { transform: 'rotate(360deg)' }
                }
              }} />
            </IconButton>
          </Tooltip>
        )}
      </Box>

      {/* Connection details dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          WebSocket Connection Status
        </DialogTitle>
        <DialogContent>
          {error && (
            <Alert
              severity="error"
              sx={{ mb: 2 }}
              action={
                <IconButton size="small" color="inherit">
                  <InfoIcon fontSize="small" />
                </IconButton>
              }
            >
              {error}
            </Alert>
          )}

          <Box sx={{ mb: 2 }}>
            <Typography variant="subtitle2" gutterBottom>
              Connection Status
            </Typography>
            <Chip
              icon={getStatusIcon()}
              label={getStatusText()}
              color={getStatusColor()}
              sx={{ mb: 1 }}
            />
            {statusDetails.lastError && (
              <Typography variant="body2" color="text.secondary">
                {statusDetails.lastError}
              </Typography>
            )}
          </Box>

          <Typography variant="body2" sx={{ mb: 2 }}>
            The WebSocket connection allows real-time data updates from your sensors.
            If you're experiencing connection issues, try reconnecting or check your network connection.
          </Typography>

          {!isConnected && (
            <Alert severity="info" sx={{ mb: 2 }}>
              Without a WebSocket connection, you won't receive real-time sensor updates.
              The dashboard will still show historical data but won't update automatically.
            </Alert>
          )}
        </DialogContent>
        <DialogActions>
          {!isConnected && (
            <Button
              onClick={handleReconnect}
              color="primary"
              disabled={reconnecting}
              startIcon={
                reconnecting ?
                <CircularProgress size={16} /> :
                <RefreshIcon />
              }
            >
              {reconnecting ? 'Reconnecting...' : 'Reconnect'}
            </Button>
          )}
          <Button onClick={() => setDialogOpen(false)}>
            Close
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default WebSocketStatus;
