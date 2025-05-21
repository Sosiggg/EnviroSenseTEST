import {
  Box,
  Typography,
  Grid,
  Avatar,
  Divider,
  Container,
  Paper,
  useTheme,
  alpha,
  Chip
} from '@mui/material';
import {
  Code as CodeIcon,
  DesktopMac as DesktopMacIcon,
  Memory as MemoryIcon,
  Assessment as AssessmentIcon,
  Engineering as EngineeringIcon,
  DataObject as DataObjectIcon,
  BarChart as BarChartIcon,
  Devices as DevicesIcon
} from '@mui/icons-material';

// Team member data
const teamMembers = [
  {
    name: 'Salas',
    role: 'Team Lead & Backend Developer',
    description: 'Responsible for the overall architecture and backend development of the EnviroSense system.',
    icon: <CodeIcon fontSize="large" />,
    secondaryIcon: <DataObjectIcon fontSize="small" />,
    color: '#2196f3',
    skills: ['API Development', 'Database Design', 'System Architecture']
  },
  {
    name: 'Nacalaban',
    role: 'Frontend Developer',
    description: 'Designs and implements the user interfaces for both mobile and web applications.',
    icon: <DesktopMacIcon fontSize="large" />,
    secondaryIcon: <DevicesIcon fontSize="small" />,
    color: '#4caf50',
    skills: ['UI/UX Design', 'React', 'Flutter']
  },
  {
    name: 'Paigna',
    role: 'IoT Specialist',
    description: 'Develops and maintains the sensor hardware and firmware for data collection.',
    icon: <MemoryIcon fontSize="large" />,
    secondaryIcon: <EngineeringIcon fontSize="small" />,
    color: '#ff9800',
    skills: ['ESP32', 'Sensor Integration', 'Firmware Development']
  },
  {
    name: 'Olandria',
    role: 'Data Analyst',
    description: 'Analyzes sensor data and develops algorithms for environmental monitoring.',
    icon: <AssessmentIcon fontSize="large" />,
    secondaryIcon: <BarChartIcon fontSize="small" />,
    color: '#9c27b0',
    skills: ['Data Visualization', 'Statistical Analysis', 'Predictive Modeling']
  }
];

const Team = () => {
  const theme = useTheme();

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      {/* Header Section */}
      <Box sx={{ textAlign: 'center', mb: 6 }}>
        <Typography
          variant="h3"
          component="h1"
          gutterBottom
          sx={{
            fontWeight: 'bold',
            background: `linear-gradient(45deg, ${theme.palette.primary.main}, ${theme.palette.secondary.main})`,
            backgroundClip: 'text',
            textFillColor: 'transparent',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            mb: 2
          }}
        >
          Our Team
        </Typography>
        <Typography
          variant="h6"
          color="text.secondary"
          sx={{
            maxWidth: 700,
            mx: 'auto',
            mb: 3
          }}
        >
          Meet the talented individuals behind the EnviroSense project
        </Typography>
        <Divider sx={{ width: 100, mx: 'auto', borderWidth: 2, borderColor: theme.palette.primary.main }} />
      </Box>

      {/* Team Lead Section */}
      <Paper
        elevation={3}
        sx={{
          mb: 6,
          borderRadius: 4,
          overflow: 'hidden',
          position: 'relative'
        }}
      >
        <Box sx={{
          height: 8,
          width: '100%',
          bgcolor: teamMembers[0].color,
          position: 'absolute',
          top: 0,
          left: 0,
          zIndex: 1
        }} />

        <Grid container sx={{ p: { xs: 3, md: 4 }, pt: { xs: 5, md: 5 } }}>
          <Grid item xs={12} md={4} sx={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            mb: { xs: 4, md: 0 },
            order: { xs: 1, md: 1 }
          }}>
            <Box sx={{ position: 'relative', textAlign: 'center', maxWidth: { xs: '100%', md: '90%' } }}>
              <Avatar
                sx={{
                  width: { xs: 140, sm: 160 },
                  height: { xs: 140, sm: 160 },
                  bgcolor: teamMembers[0].color,
                  color: 'white',
                  boxShadow: `0 8px 24px ${alpha(teamMembers[0].color, 0.4)}`,
                  mb: 2,
                  mx: 'auto'
                }}
              >
                {teamMembers[0].icon}
              </Avatar>
              <Typography variant="h4" sx={{ fontWeight: 'bold', mb: 1, fontSize: { xs: '1.75rem', sm: '2.125rem' } }}>
                {teamMembers[0].name}
              </Typography>
              <Typography
                variant="subtitle1"
                sx={{
                  color: teamMembers[0].color,
                  fontWeight: 'medium',
                  mb: 2
                }}
              >
                {teamMembers[0].role}
              </Typography>

              <Box sx={{
                display: 'flex',
                justifyContent: 'center',
                gap: 1,
                flexWrap: 'wrap'
              }}>
                {teamMembers[0].skills.map((skill, idx) => (
                  <Chip
                    key={idx}
                    label={skill}
                    size="small"
                    sx={{
                      bgcolor: alpha(teamMembers[0].color, 0.1),
                      color: teamMembers[0].color,
                      fontWeight: 'medium',
                      mb: 1
                    }}
                  />
                ))}
              </Box>
            </Box>
          </Grid>

          <Grid item xs={12} md={8} sx={{
            pl: { md: 6 },
            order: { xs: 2, md: 2 },
            borderTop: { xs: `1px solid ${alpha(teamMembers[0].color, 0.2)}`, md: 'none' },
            pt: { xs: 3, md: 0 },
            mt: { xs: 2, md: 0 }
          }}>
            <Box sx={{
              height: '100%',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'center',
              textAlign: { xs: 'center', md: 'left' }
            }}>
              <Typography
                variant="h5"
                gutterBottom
                sx={{
                  fontWeight: 'bold',
                  color: teamMembers[0].color,
                  display: { xs: 'none', md: 'block' }
                }}
              >
                Team Lead
              </Typography>

              <Typography variant="body1" sx={{ mb: 3, lineHeight: 1.8 }}>
                {teamMembers[0].description} As the team lead, {teamMembers[0].name} coordinates the development efforts
                and ensures that all components of the EnviroSense system work together seamlessly. With expertise in
                backend development and system architecture, {teamMembers[0].name} has designed a robust and scalable
                platform for environmental monitoring.
              </Typography>

              <Box sx={{
                p: 2,
                bgcolor: alpha(teamMembers[0].color, 0.05),
                borderRadius: 2,
                borderLeft: { xs: 'none', md: `4px solid ${teamMembers[0].color}` },
                borderTop: { xs: `4px solid ${teamMembers[0].color}`, md: 'none' }
              }}>
                <Typography variant="body2" sx={{ fontStyle: 'italic', color: 'text.secondary' }}>
                  "Our goal with EnviroSense is to create an intuitive platform that makes environmental
                  monitoring accessible and actionable for everyone."
                </Typography>
              </Box>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Team Members Section */}
      <Typography variant="h5" sx={{ mb: 3, fontWeight: 'bold' }}>
        Team Members
      </Typography>

      <Grid container spacing={3}>
        {teamMembers.slice(1).map((member, index) => (
          <Grid item xs={12} sm={6} md={4} key={index}>
            <Paper
              elevation={2}
              sx={{
                height: '100%',
                borderRadius: 3,
                overflow: 'hidden',
                transition: 'all 0.3s ease',
                '&:hover': {
                  transform: 'translateY(-5px)',
                  boxShadow: 6,
                },
                display: 'flex',
                flexDirection: 'column',
                position: 'relative'
              }}
            >
              <Box sx={{
                height: 6,
                width: '100%',
                bgcolor: member.color,
                position: 'absolute',
                top: 0,
                left: 0
              }} />

              <Box sx={{ p: { xs: 2, sm: 3 }, pb: { xs: 2, sm: 2 } }}>
                <Box sx={{
                  display: 'flex',
                  alignItems: 'center',
                  mb: 2,
                  flexDirection: { xs: 'column', sm: 'row' },
                  textAlign: { xs: 'center', sm: 'left' },
                  gap: { xs: 1, sm: 0 }
                }}>
                  <Avatar
                    sx={{
                      width: { xs: 80, sm: 70 },
                      height: { xs: 80, sm: 70 },
                      bgcolor: member.color,
                      color: 'white',
                      mr: { xs: 0, sm: 2 },
                      mb: { xs: 1, sm: 0 }
                    }}
                  >
                    {member.icon}
                  </Avatar>

                  <Box>
                    <Typography variant="h6" sx={{ fontWeight: 'bold' }}>
                      {member.name}
                    </Typography>
                    <Typography
                      variant="subtitle2"
                      sx={{
                        color: member.color,
                        fontWeight: 'medium'
                      }}
                    >
                      {member.role}
                    </Typography>
                  </Box>
                </Box>

                <Divider sx={{ mb: 2 }} />

                <Typography
                  variant="body2"
                  color="text.secondary"
                  sx={{
                    mb: 2,
                    textAlign: { xs: 'center', sm: 'left' }
                  }}
                >
                  {member.description}
                </Typography>

                <Box sx={{
                  display: 'flex',
                  flexWrap: 'wrap',
                  gap: 1,
                  mt: 'auto',
                  justifyContent: { xs: 'center', sm: 'flex-start' }
                }}>
                  {member.skills.map((skill, idx) => (
                    <Chip
                      key={idx}
                      label={skill}
                      size="small"
                      sx={{
                        bgcolor: alpha(member.color, 0.1),
                        color: member.color,
                        fontSize: '0.7rem'
                      }}
                    />
                  ))}
                </Box>
              </Box>
            </Paper>
          </Grid>
        ))}
      </Grid>

      {/* About Section */}
      <Paper
        elevation={3}
        sx={{
          mt: 6,
          p: { xs: 3, md: 4 },
          borderRadius: 4,
          position: 'relative',
          overflow: 'hidden',
          bgcolor: alpha(theme.palette.primary.main, 0.02)
        }}
      >
        <Box
          sx={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: { xs: 4, md: 8 },
            height: '100%',
            bgcolor: theme.palette.primary.main
          }}
        />

        <Typography
          variant="h4"
          component="h2"
          gutterBottom
          sx={{
            fontWeight: 'bold',
            pl: { xs: 2, md: 3 },
            color: theme.palette.primary.main,
            fontSize: { xs: '1.75rem', md: '2.125rem' },
            textAlign: { xs: 'center', md: 'left' }
          }}
        >
          About EnviroSense
        </Typography>

        <Typography
          variant="body1"
          sx={{
            pl: { xs: 2, md: 3 },
            lineHeight: 1.8,
            mb: 3,
            textAlign: { xs: 'center', md: 'left' }
          }}
        >
          EnviroSense is an environmental monitoring system that collects real-time data from sensors
          to provide insights into temperature, humidity, and obstacle detection. Our mission is to
          create a user-friendly platform for monitoring environmental conditions in various settings.
        </Typography>

        <Box
          sx={{
            display: 'flex',
            flexDirection: { xs: 'column', md: 'row' },
            gap: { xs: 3, md: 4 },
            pl: { xs: 2, md: 3 },
            mt: 4
          }}
        >
          <Box sx={{ flex: 1, textAlign: { xs: 'center', md: 'left' } }}>
            <Typography variant="h6" sx={{ mb: 1, color: theme.palette.primary.main, fontWeight: 'medium' }}>
              Hardware
            </Typography>
            <Typography variant="body2" sx={{ lineHeight: 1.8 }}>
              The system uses ESP32 microcontrollers connected to DHT22 temperature/humidity sensors and
              obstacle detection sensors to provide accurate, real-time environmental data.
            </Typography>
          </Box>

          <Box sx={{ flex: 1, textAlign: { xs: 'center', md: 'left' } }}>
            <Typography variant="h6" sx={{ mb: 1, color: theme.palette.primary.main, fontWeight: 'medium' }}>
              Software
            </Typography>
            <Typography variant="body2" sx={{ lineHeight: 1.8 }}>
              With both web and mobile interfaces built with React and Flutter, users can monitor their
              environment from anywhere, at any time, with real-time updates via WebSockets.
            </Typography>
          </Box>
        </Box>
      </Paper>
    </Container>
  );
};

export default Team;
