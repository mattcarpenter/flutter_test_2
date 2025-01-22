enum ShoppingListRoutes {
  root,
  subPage,
}

extension ShoppingListRoutesExtension on ShoppingListRoutes {
  String get path {
    switch (this) {
      case ShoppingListRoutes.root:
        return '/';
      case ShoppingListRoutes.subPage:
        return '/sub';
    }
  }
}
