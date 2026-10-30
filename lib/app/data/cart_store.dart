import 'package:flutter/foundation.dart';

import 'hair_style.dart';

/// Một mẫu tóc trong giỏ, kèm màu và tùy biến khách đã chọn.
class CartItem {
  const CartItem({
    required this.style,
    required this.color,
    required this.length,
    required this.bangs,
    required this.texture,
  });

  final HairStyle style;
  final HairColor color;
  final String length;
  final String bangs;
  final String texture;
}

/// Giỏ hàng tạm trong bộ nhớ, sau này nối với màn Đặt lịch / thanh toán.
class CartStore extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get count => _items.length;

  void add(CartItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }
}

final cartStore = CartStore();
