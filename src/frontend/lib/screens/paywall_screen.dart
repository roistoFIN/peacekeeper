import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    final offerings = await SubscriptionService.getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    }
  }

  Future<void> _purchase(Package package) async {
    setState(() => _isLoading = true);
    final isSuccess = await SubscriptionService.purchasePackage(package);
    if (mounted) {
      setState(() => _isLoading = false);
      if (isSuccess) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Welcome to Premium!")));
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    final isSuccess = await SubscriptionService.restorePurchases();
    if (mounted) {
      setState(() => _isLoading = false);
      if (isSuccess) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Purchases restored!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No active subscriptions found.")));
      }
    }
  }

  Future<void> _showRedeemDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Redeem Code"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter code (e.g. SAVE2026)", border: OutlineInputBorder()),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final error = await SubscriptionService.redeemCode(controller.text.trim());
              setState(() => _isLoading = false);
              
              if (mounted) {
                if (error == null) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code redeemed! Premium unlocked.")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                }
              }
            }, 
            child: const Text("Redeem")
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Unlock Peacekeeper"), actions: [
        TextButton(onPressed: _restore, child: const Text("Restore"))
      ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _offerings == null || _offerings!.current == null
                      ? const Center(child: Text("No offerings available. check configuration."))
                      : ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            const Text("Choose your plan", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 32),
                            ..._offerings!.current!.availablePackages.map((package) => _buildPackageCard(package)),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: TextButton(
                    onPressed: _showRedeemDialog,
                    child: const Text("Have a gift code? Redeem here", style: TextStyle(decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPackageCard(Package package) {
    final isMonthly = package.packageType == PackageType.monthly;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: isMonthly ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Text(package.storeProduct.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(package.storeProduct.description),
        trailing: Text(package.storeProduct.priceString, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
        onTap: () => _purchase(package),
      ),
    );
  }
}
