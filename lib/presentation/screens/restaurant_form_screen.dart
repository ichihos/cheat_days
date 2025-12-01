import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/restaurant.dart';
import '../providers/firebase_providers.dart';

class RestaurantFormScreen extends ConsumerStatefulWidget {
  final String? cheatDayId;
  final Restaurant? existingRestaurant;

  const RestaurantFormScreen({
    super.key,
    this.cheatDayId,
    this.existingRestaurant,
  });

  @override
  ConsumerState<RestaurantFormScreen> createState() => _RestaurantFormScreenState();
}

class _RestaurantFormScreenState extends ConsumerState<RestaurantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _mapUrlController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  final List<TextEditingController> _tagControllers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRestaurant != null) {
      _nameController.text = widget.existingRestaurant!.name;
      _addressController.text = widget.existingRestaurant!.address;
      _phoneController.text = widget.existingRestaurant!.phoneNumber ?? '';
      _websiteController.text = widget.existingRestaurant!.website ?? '';
      _mapUrlController.text = widget.existingRestaurant!.mapUrl ?? '';
      _latitudeController.text = widget.existingRestaurant!.latitude?.toString() ?? '';
      _longitudeController.text = widget.existingRestaurant!.longitude?.toString() ?? '';

      for (var tag in widget.existingRestaurant!.tags) {
        final controller = TextEditingController(text: tag);
        _tagControllers.add(controller);
      }
    } else {
      // Start with one empty tag
      _tagControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _mapUrlController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    for (var controller in _tagControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addTag() {
    setState(() {
      _tagControllers.add(TextEditingController());
    });
  }

  void _removeTag(int index) {
    setState(() {
      _tagControllers[index].dispose();
      _tagControllers.removeAt(index);
    });
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.cheatDayId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投稿に紐付けてお店を登録してください')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tags = _tagControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final restaurant = Restaurant(
        id: widget.existingRestaurant?.id ??
            '${widget.cheatDayId}_restaurant_${DateTime.now().millisecondsSinceEpoch}',
        cheatDayId: widget.cheatDayId!,
        name: _nameController.text,
        address: _addressController.text,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
        latitude: _latitudeController.text.isNotEmpty
            ? double.tryParse(_latitudeController.text)
            : null,
        longitude: _longitudeController.text.isNotEmpty
            ? double.tryParse(_longitudeController.text)
            : null,
        mapUrl: _mapUrlController.text.isNotEmpty ? _mapUrlController.text : null,
        tags: tags,
        createdAt: widget.existingRestaurant?.createdAt ?? DateTime.now(),
      );

      final repository = ref.read(restaurantRepositoryProvider);

      if (widget.existingRestaurant != null) {
        await repository.updateRestaurant(restaurant);
      } else {
        await repository.addRestaurant(restaurant);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('お店情報を保存しました')),
        );
        Navigator.pop(context, restaurant);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRestaurant != null ? 'お店情報編集' : 'お店情報登録'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRestaurant,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 店名
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '店名',
                hintText: '例: 唐揚げ専門店 鳥よし',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '店名を入力してください';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 住所
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '住所',
                hintText: '例: 東京都渋谷区...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '住所を入力してください';
                }
                return null;
              },
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // 電話番号
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '電話番号（任意）',
                hintText: '例: 03-1234-5678',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 16),

            // ウェブサイト
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'ウェブサイト（任意）',
                hintText: '例: https://example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 16),

            // マップURL
            TextFormField(
              controller: _mapUrlController,
              decoration: const InputDecoration(
                labelText: 'マップURL（任意）',
                hintText: '例: Google Maps のURL',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 16),

            // 緯度・経度
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: '緯度（任意）',
                      hintText: '35.6895',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: '経度（任意）',
                      hintText: '139.6917',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // タグ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'タグ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add_circle),
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._tagControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: '例: ランチ、ディナー、デート',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    if (_tagControllers.length > 1)
                      IconButton(
                        onPressed: () => _removeTag(index),
                        icon: const Icon(Icons.remove_circle),
                        color: Colors.red,
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
