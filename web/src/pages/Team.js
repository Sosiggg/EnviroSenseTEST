import React from 'react';
import { 
  Box, 
  Typography, 
  Grid, 
  Card, 
  CardContent, 
  CardMedia, 
  Avatar,
  Divider
} from '@mui/material';
import {
  Code as CodeIcon,
  DesktopMac as DesktopMacIcon,
  Memory as MemoryIcon,
  Assessment as AssessmentIcon
} from '@mui/icons-material';

// Team member data
const teamMembers = [
  {
    name: 'Salas',
    role: 'Team Lead & Backend Developer',
    description: 'Responsible for the overall architecture and backend development of the EnviroSense system.',
    icon: <CodeIcon fontSize="large" />,
    color: '#2196f3'
  },
  {
    name: 'Nacalaban',
    role: 'Frontend Developer',
    description: 'Designs and implements the user interfaces for both mobile and web applications.',
    icon: <DesktopMacIcon fontSize="large" />,
    color: '#4caf50'
  },
  {
    name: 'Paigna',
    role: 'IoT Specialist',
    description: 'Develops and maintains the sensor hardware and firmware for data collection.',
    icon: <MemoryIcon fontSize="large" />,
    color: '#ff9800'
  },
  {
    name: 'Olandria',
    role: 'Data Analyst',
    description: 'Analyzes sensor data and develops algorithms for environmental monitoring.',
    icon: <AssessmentIcon fontSize="large" />,
    color: '#9c27b0'
  }
];

const Team = () => {
  return (
    <Box>
      <Typography variant="h4" component="h1" gutterBottom>
        Our Team
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4 }}>
        Meet the talented individuals behind the EnviroSense project
      </Typography>

      <Grid container spacing={4}>
        {teamMembers.map((member, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card 
              sx={{ 
                height: '100%',
                display: 'flex',
                flexDirection: 'column',
                transition: 'transform 0.3s ease',
                '&:hover': {
                  transform: 'translateY(-8px)',
                  boxShadow: 6,
                },
              }}
            >
              <Box 
                sx={{ 
                  display: 'flex', 
                  justifyContent: 'center',
                  alignItems: 'center',
                  pt: 3,
                  pb: 2
                }}
              >
                <Avatar 
                  sx={{ 
                    width: 80, 
                    height: 80, 
                    bgcolor: member.color,
                  }}
                >
                  {member.icon}
                </Avatar>
              </Box>
              <CardContent sx={{ flexGrow: 1, textAlign: 'center' }}>
                <Typography gutterBottom variant="h5" component="div">
                  {member.name}
                </Typography>
                <Typography 
                  variant="subtitle1" 
                  color="text.secondary" 
                  sx={{ mb: 2, fontWeight: 'medium' }}
                >
                  {member.role}
                </Typography>
                <Divider sx={{ mb: 2 }} />
                <Typography variant="body2" color="text.secondary">
                  {member.description}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Box sx={{ mt: 6, textAlign: 'center' }}>
        <Typography variant="h5" component="h2" gutterBottom>
          About EnviroSense
        </Typography>
        <Typography variant="body1" sx={{ maxWidth: 800, mx: 'auto' }}>
          EnviroSense is an environmental monitoring system that collects real-time data from sensors
          to provide insights into temperature, humidity, and obstacle detection. Our mission is to
          create a user-friendly platform for monitoring environmental conditions in various settings.
        </Typography>
      </Box>
    </Box>
  );
};

export default Team;
