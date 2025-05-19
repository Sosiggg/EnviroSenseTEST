import 'package:flutter/material.dart';

class TeamMember {
  final String name;
  final String role;
  final String? photoAsset;
  final IconData icon;
  final String description;

  const TeamMember({
    required this.name,
    required this.role,
    this.photoAsset,
    required this.icon,
    required this.description,
  });
}

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Team members data
    final List<TeamMember> teamMembers = [
      const TeamMember(
        name: 'Salas',
        role: 'Team Lead & Fullstack Developer',
        icon: Icons.code,
        description:
            'Responsible for the overall architecture, frontend, and backend development of EnviroSense.',
      ),
      const TeamMember(
        name: 'Nacalaban',
        role: 'Backend Developer',
        icon: Icons.design_services,
        description:
            'Designed and implemented the user interface and experience of the EnviroSense mobile app.',
      ),
      const TeamMember(
        name: 'Paigna',
        role: 'Frontemd Developer & IoT Specialist',
        icon: Icons.sensors,
        description:
            'Developed the sensor integration and data collection systems for EnviroSense.',
      ),
      const TeamMember(
        name: 'Olandria',
        role: 'Frontend Developer & Data Analyst',
        icon: Icons.analytics,
        description:
            'Created data visualization and analytics features for environmental monitoring.',
      ),
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Header
            Text(
              'Meet Our Team',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The talented individuals who made EnviroSense possible',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Team Members
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: teamMembers.length,
              itemBuilder: (context, index) {
                final member = teamMembers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // For small screens, use a column layout
                        if (constraints.maxWidth < 400) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Member Photo or Icon
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(51), // 0.2 * 255 = 51
                                child:
                                    member.photoAsset != null
                                        ? ClipOval(
                                          child: Image.asset(
                                            member.photoAsset!,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                        : Icon(
                                          member.icon,
                                          size: 40,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                              ),
                              const SizedBox(height: 16),

                              // Member Details
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    member.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    member.role,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    member.description,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          // For larger screens, use the original row layout
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Member Photo or Icon
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(51), // 0.2 * 255 = 51
                                child:
                                    member.photoAsset != null
                                        ? ClipOval(
                                          child: Image.asset(
                                            member.photoAsset!,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                        : Icon(
                                          member.icon,
                                          size: 40,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                              ),
                              const SizedBox(width: 16),

                              // Member Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      member.role,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      member.description,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),

            // Project Information
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About EnviroSense',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'EnviroSense is an environmental monitoring system that uses ESP32 devices to collect temperature, humidity, and obstacle detection data. The data is sent to a FastAPI backend and displayed in this Flutter mobile application.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Technologies Used:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTechItem(
                      context,
                      Icons.developer_board,
                      'ESP32 for sensor data collection',
                    ),
                    _buildTechItem(
                      context,
                      Icons.api,
                      'FastAPI backend with JWT authentication',
                    ),
                    _buildTechItem(
                      context,
                      Icons.storage,
                      'PostgreSQL database',
                    ),
                    _buildTechItem(
                      context,
                      Icons.web,
                      'WebSockets for real-time updates',
                    ),
                    _buildTechItem(
                      context,
                      Icons.phone_android,
                      'Flutter for cross-platform mobile app',
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            const SizedBox(height: 24),
            Center(
              child: Text(
                '© 2025 EnviroSense Team',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
