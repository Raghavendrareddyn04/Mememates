import 'package:flutter/material.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
              Colors.purple.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Go Premium',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock exclusive features and enhance your experience',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSubscriptionCard(
                    title: 'Monthly',
                    price: '\$4.99',
                    features: const [
                      'AI-curated matches',
                      'Create custom anthems',
                      'Enhanced profile visibility',
                      'Ad-free experience',
                    ],
                    onSubscribe: () => _handleSubscription(context, 'monthly'),
                  ),
                  const SizedBox(height: 16),
                  _buildSubscriptionCard(
                    title: 'Yearly',
                    price: '\$49.99',
                    features: const [
                      'All Monthly features',
                      '2 months free',
                      'Priority support',
                      'Early access to new features',
                    ],
                    isPopular: true,
                    onSubscribe: () => _handleSubscription(context, 'yearly'),
                  ),
                  const SizedBox(height: 32),
                  _buildInAppPurchasesSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required String title,
    required String price,
    required List<String> features,
    bool isPopular = false,
    required VoidCallback onSubscribe,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isPopular ? Colors.white : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: isPopular
            ? Border.all(color: Colors.deepPurple, width: 2)
            : null,
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Text(
                'MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isPopular ? Colors.black : Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: isPopular ? Colors.deepPurple : Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: isPopular ? Colors.deepPurple : Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            feature,
                            style: TextStyle(
                              color: isPopular ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isPopular ? Colors.deepPurple : Colors.white,
                    foregroundColor:
                        isPopular ? Colors.white : Colors.deepPurple,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Subscribe'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInAppPurchasesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'One-time Purchases',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
          children: [
            _buildPurchaseCard(
              title: 'Feature Profile',
              price: '\$2.99',
              icon: Icons.star,
              description: 'Boost your profile visibility for 24 hours',
              onPurchase: () => _handlePurchase(context, 'feature_profile'),
            ),
            _buildPurchaseCard(
              title: 'Meme Pack',
              price: '\$0.99',
              icon: Icons.emoji_emotions,
              description: 'Unlock exclusive meme templates and stickers',
              onPurchase: () => _handlePurchase(context, 'meme_pack'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPurchaseCard({
    required String title,
    required String price,
    required IconData icon,
    required String description,
    required VoidCallback onPurchase,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            price,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onPurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
              minimumSize: const Size(double.infinity, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Buy'),
          ),
        ],
      ),
    );
  }

  void _handleSubscription(BuildContext context, String plan) {
    // Here you would implement the subscription logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscribe'),
        content: Text('Processing $plan subscription...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handlePurchase(BuildContext context, String item) {
    // Here you would implement the purchase logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase'),
        content: Text('Processing $item purchase...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}