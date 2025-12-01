import '../../domain/entities/restaurant.dart';
import '../../domain/repositories/restaurant_repository.dart';
import '../datasources/firestore_service.dart';
import '../models/restaurant_model.dart';

class FirebaseRestaurantRepository implements RestaurantRepository {
  final FirestoreService firestoreService;

  FirebaseRestaurantRepository(this.firestoreService);

  @override
  Future<Restaurant?> getRestaurantByCheatDayId(String cheatDayId) async {
    return await firestoreService.getRestaurantByCheatDayId(cheatDayId);
  }

  @override
  Future<void> addRestaurant(Restaurant restaurant) async {
    await firestoreService.addRestaurant(RestaurantModel.fromEntity(restaurant));
  }

  @override
  Future<void> updateRestaurant(Restaurant restaurant) async {
    await firestoreService.updateRestaurant(RestaurantModel.fromEntity(restaurant));
  }

  @override
  Future<void> deleteRestaurant(String id) async {
    await firestoreService.deleteRestaurant(id);
  }
}
