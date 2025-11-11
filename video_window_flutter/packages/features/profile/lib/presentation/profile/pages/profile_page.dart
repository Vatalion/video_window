import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/data/repositories/profile/profile_repository.dart';
import 'package:video_window_client/video_window_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import 'privacy_settings_page.dart';
import 'notification_preferences_page.dart';
import '../widgets/account/account_tab.dart';

/// Profile management page with tabs
/// AC1: Complete profile management interface with avatar/media upload, personal information editing
/// Story 3-5: Extended with Account tab for DSAR and account management
class ProfilePage extends StatefulWidget {
  final int userId;

  const ProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get client from context or create new instance
    // TODO: Use proper dependency injection when available
    final client = Client('http://localhost:8080/')
      ..connectivityMonitor = FlutterConnectivityMonitor();

    return BlocProvider(
      create: (context) => ProfileBloc(
        ProfileRepository(client),
      )..add(ProfileLoadRequested(widget.userId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Profile'),
              Tab(icon: Icon(Icons.privacy_tip), text: 'Privacy'),
              Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
              Tab(icon: Icon(Icons.settings), text: 'Account'),
            ],
          ),
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
                            .add(ProfileLoadRequested(widget.userId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // Profile Tab
                if (state is ProfileLoaded)
                  _buildProfileTab(context, state.profile)
                else
                  const Center(child: Text('No profile data')),

                // Privacy Tab
                PrivacySettingsPage(userId: widget.userId),

                // Notifications Tab
                NotificationPreferencesPage(userId: widget.userId),

                // Account Tab
                AccountTab(
                  userId: widget.userId,
                  lastAuthTime: DateTime.now().subtract(
                    const Duration(minutes: 5),
                  ), // TODO: Get actual last auth time from session
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, Map<String, dynamic> profile) {
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
                      widget.userId,
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
        ],
      ),
    );
  }
}
