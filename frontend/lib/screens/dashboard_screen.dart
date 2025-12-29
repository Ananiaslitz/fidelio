import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../config/supabase_config.dart';
import '../models/merchant.dart';
import '../widgets/merchant_card.dart';
import '../widgets/category_grid.dart';
import '../widgets/promo_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock data for now, actual user balance logic can wait
  final double _balance = 1250.00;
  
  List<Merchant> _merchants = [];
  bool _isLoadingMerchants = true;
  String _currentAddress = 'Localizando...';
  Position? _currentPosition;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await _determinePosition();
      setState(() {
        _currentPosition = position;
      });
      await _getAddressFromLatLng(position);
      await _fetchNearbyMerchants();
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _currentAddress = 'Localização indisponível';
        _isLoadingMerchants = false;
      });
       // Fallback to default/test location if permission denied
       _fetchNearbyMerchants(useFallback: true);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = '${place.thoroughfare ?? place.subLocality}, ${place.subThoroughfare ?? ''}';
          if (_currentAddress.trim() == ',') _currentAddress = place.subLocality ?? place.locality ?? 'Desconhecido';
        });
      }
    } catch (e) {
      debugPrint("Error decoding address: $e");
      // On web cors might block geocoding or limit it. 
      // Fallback:
      setState(() {
        _currentAddress = 'Minha Localização';
      });
    }
  }

  Future<void> _fetchNearbyMerchants({bool useFallback = false}) async {
    setState(() {
      _isLoadingMerchants = true;
    });

    try {
      double userLat = -23.561414; // Fallback: Av Paulista
      double userLong = -46.655881;

      if (!useFallback && _currentPosition != null) {
        userLat = _currentPosition!.latitude;
        userLong = _currentPosition!.longitude;
      }

      final data = await SupabaseConfig.client.rpc(
        'get_nearby_merchants',
        params: {
          'user_lat': userLat,
          'user_long': userLong,
          'radius_km': 100.0,
          'filter_category': _selectedCategory,
        },
      );
      
      if (mounted) {
        setState(() {
          _merchants = (data as List).map((e) => Merchant.fromJson(e)).toList();
          _isLoadingMerchants = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching merchants: $e');
      if (mounted) {
        setState(() {
          _isLoadingMerchants = false;
        });
      }
    }
  }

  Future<void> _handleLocationTap() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        _initializeLocation();
      }
    } else if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    } else {
      // Already has permission, refresh location
      _initializeLocation();
    }
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _fetchNearbyMerchants();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = SupabaseConfig.client.auth.currentUser;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Location
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              floating: true,
              elevation: 0,
              title: InkWell(
                onTap: _handleLocationTap,
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _currentAddress, 
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: theme.primaryColor),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () {},
                ),
              ],
            ),
            
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Categories
                   const SizedBox(height: 16),
                   CategoryGrid(
                     onCategorySelected: _onCategorySelected,
                     selectedCategory: _selectedCategory,
                   ),
                   
                   // Banners
                   const SizedBox(height: 24),
                   const PromoBanner(),
                   const SizedBox(height: 24),

                   // "Sticky" Header for List
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                     child: Text(
                      _selectedCategory == null ? 'Lojas Próximas' : 'Lojas em $_selectedCategory',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                     ),
                   ),
                   const SizedBox(height: 16),
                ],
              ),
            ),

            // Merchant List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _isLoadingMerchants
                  ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                  : _merchants.isEmpty 
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('Nenhum parceiro encontrado nesta categoria/região.'),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return MerchantCard(
                              merchant: _merchants[index],
                              onTap: () {},
                            );
                          },
                          childCount: _merchants.length,
                        ),
                      ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}
