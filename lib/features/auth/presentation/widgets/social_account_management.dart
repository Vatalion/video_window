import 'package:flutter/material.dart';
import 'package:video_window/features/auth/domain/models/social_account_model.dart';

class SocialAccountManagement extends StatelessWidget {
  final List<SocialAccountModel> linkedAccounts;
  final Function(SocialAccountModel) onUnlinkAccount;
  final Function(SocialProvider) onLinkAccount;

  const SocialAccountManagement({
    super.key,
    required this.linkedAccounts,
    required this.onUnlinkAccount,
    required this.onLinkAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Linked Accounts', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ..._buildAccountList(context),
        const SizedBox(height: 24),
        Text(
          'Link New Account',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _buildAvailableProviders(context),
      ],
    );
  }

  List<Widget> _buildAccountList(BuildContext context) {
    if (linkedAccounts.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No social accounts linked',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ),
          ),
        ),
      ];
    }

    return linkedAccounts
        .map((account) => _buildAccountCard(context, account))
        .toList();
  }

  Widget _buildAccountCard(BuildContext context, SocialAccountModel account) {
    final providerInfo = _getProviderInfo(account.provider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: providerInfo.color.withOpacity(0.1),
              ),
              child: Icon(
                providerInfo.icon,
                color: providerInfo.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerInfo.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (account.email != null)
                    Text(
                      account.email!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: account.isActive
                              ? Colors.green[100]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          account.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: account.isActive
                                ? Colors.green[800]
                                : Colors.grey[800],
                          ),
                        ),
                      ),
                      if (account.isTokenExpired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Expired',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () => onUnlinkAccount(account),
              icon: const Icon(Icons.link_off),
              color: Colors.red,
              tooltip: 'Unlink account',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableProviders(BuildContext context) {
    final availableProviders = SocialProvider.values
        .where(
          (provider) =>
              !linkedAccounts.any((account) => account.provider == provider),
        )
        .toList();

    if (availableProviders.isEmpty) {
      return const Text('All social accounts are already linked');
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: availableProviders.map((provider) {
        final providerInfo = _getProviderInfo(provider);
        return OutlinedButton.icon(
          onPressed: () => onLinkAccount(provider),
          icon: Icon(providerInfo.icon),
          label: Text('Link ${providerInfo.name}'),
          style: OutlinedButton.styleFrom(
            foregroundColor: providerInfo.color,
            side: BorderSide(color: providerInfo.color),
          ),
        );
      }).toList(),
    );
  }

  ProviderInfo _getProviderInfo(SocialProvider provider) {
    switch (provider) {
      case SocialProvider.google:
        return const ProviderInfo(
          name: 'Google',
          icon: Icons.g_mobile,
          color: Colors.red,
        );
      case SocialProvider.apple:
        return const ProviderInfo(
          name: 'Apple',
          icon: Icons.apple,
          color: Colors.black,
        );
      case SocialProvider.facebook:
        return const ProviderInfo(
          name: 'Facebook',
          icon: Icons.facebook,
          color: Colors.blue,
        );
    }
  }
}

class ProviderInfo {
  final String name;
  final IconData icon;
  final Color color;

  const ProviderInfo({
    required this.name,
    required this.icon,
    required this.color,
  });
}
