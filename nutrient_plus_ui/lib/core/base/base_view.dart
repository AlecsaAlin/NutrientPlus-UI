import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'base_viewmodel.dart';

/// Base View widget that provides ViewModel binding
/// Use this as a base for all screens/views
abstract class BaseView<T extends BaseViewModel> extends StatefulWidget {
  const BaseView({super.key});
}

abstract class BaseViewState<T extends BaseViewModel, V extends BaseView<T>> extends State<V> {
  late T viewModel;

  /// Override to create the ViewModel instance
  T createViewModel();

  /// Called after ViewModel is created, override for initialization
  void onViewModelReady(T viewModel) {}

  @override
  void initState() {
    super.initState();
    viewModel = createViewModel();
    onViewModelReady(viewModel);
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>.value(
      value: viewModel,
      child: Consumer<T>(
        builder: (context, viewModel, child) {
          return buildView(context, viewModel);
        },
      ),
    );
  }

  /// Override to build the view with the ViewModel
  Widget buildView(BuildContext context, T viewModel);
}
