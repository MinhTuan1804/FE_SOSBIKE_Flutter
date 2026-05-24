import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/find_shop/widgets/shop_list_view.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/find_shop/widgets/route_directions_view.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/screens/find_shop/widgets/completion_dialog_view.dart';

enum FindShopStep {
  list,
  directions,
  completed
}

class FindShopFlowPage extends StatefulWidget {
  const FindShopFlowPage({super.key});

  @override
  State<FindShopFlowPage> createState() => _FindShopFlowPageState();
}

class _FindShopFlowPageState extends State<FindShopFlowPage> {
  FindShopStep _currentStep = FindShopStep.list;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case FindShopStep.list:
        return ShopListView(
          onBack: () => Navigator.of(context).pop(),
          onNavigate: () {
            setState(() {
              _currentStep = FindShopStep.directions;
            });
          },
        );
      case FindShopStep.directions:
        return RouteDirectionsView(
          onBack: () {
            setState(() {
              _currentStep = FindShopStep.list;
            });
          },
          onArrive: () {
            setState(() {
              _currentStep = FindShopStep.completed;
            });
          },
        );
      case FindShopStep.completed:
        return CompletionDialogView(
          onComplete: () => Navigator.of(context).pop(),
        );
    }
  }
}
