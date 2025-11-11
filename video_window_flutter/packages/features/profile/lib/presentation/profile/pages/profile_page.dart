import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/data/repositories/profile/profile_repository.dart';
import 'package:video_window_client/video_window_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

/// Profile management page
/// AC1: Complete profile management interface with avatar/media upload, personal information editing
class ProfilePage extends StatelessWidget {
  final int userId;

  const ProfilePage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    // Get client from context or create new instance
    // TODO: Use proper dependency injection when available
    final client = Client('http://localhost:8080/')
      ..connectivityMonitor = FlutterConnectivityMonitor();

    return BlocProvider(
      create: (context) => ProfileBloc(
        ProfileRepository(client),
      )..add(ProfileLoadRequested(userId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<ProfileBloc>()
                            .add(ProfileLoadRequested(userId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is ProfileLoaded) {
              return _buildProfileForm(context, state.profile);
            }

            return const Center(child: Text('No profile data'));
          },
        ),
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context, Map<String, dynamic> profile) {
    final usernameController =
        TextEditingController(text: profile['username']?.toString());
    final fullNameController =
        TextEditingController(text: profile['fullName']?.toString());
    final bioController =
        TextEditingController(text: profile['bio']?.toString());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar section
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: profile['avatarUrl'] != null
                  ? NetworkImage(profile['avatarUrl'].toString())
                  : null,
              child: profile['avatarUrl'] == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement avatar upload
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Avatar upload not yet implemented')),
              );
            },
            child: const Text('Change Avatar'),
          ),
          const SizedBox(height: 24),
          // Username field
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          // Full name field
          TextField(
            controller: fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          // Bio field
          TextField(
            controller: bioController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Bio',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          // Save button
          ElevatedButton(
            onPressed: () {
              context.read<ProfileBloc>().add(
                    ProfileUpdateRequested(
                      userId,
                      {
                        'username': usernameController.text,
                        'fullName': fullNameController.text,
                        'bio': bioController.text,
                      },
                    ),
                  );
            },
            child: const Text('Save Profile'),
          ),
          const SizedBox(height: 16),
          // Privacy settings link
          TextButton(
            onPressed: () {
              // TODO: Navigate to privacy settings page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Privacy settings not yet implemented')),
              );
            },
            child: const Text('Privacy Settings'),
          ),
          // Notification preferences link
          TextButton(
            onPressed: () {
              // TODO: Navigate to notification preferences page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Notification preferences not yet implemented')),
              );
            },
            child: const Text('Notification Preferences'),
          ),
          // DSAR section
          const Divider(),
          const Text(
            'Data Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              context.read<ProfileBloc>().add(ExportUserDataRequested(userId));
            },
            child: const Text('Export My Data'),
          ),
          TextButton(
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'Are you sure you want to delete all your data? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context
                            .read<ProfileBloc>()
                            .add(DeleteUserDataRequested(userId));
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Delete My Data',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
