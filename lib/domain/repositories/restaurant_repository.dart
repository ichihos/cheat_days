import '../entities/restaurant.dart';

abstract class RestaurantRepository {
  Future<Restaurant?> getRestaurantByCheatDayId(String cheatDayId);
  Future<void> addRestaurant(Restaurant restaurant);
  Future<void> updateRestaurant(Restaurant restaurant);
  Future<void> deleteRestaurant(String id);
}
