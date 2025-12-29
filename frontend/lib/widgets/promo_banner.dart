import 'dart:async'; // Added
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  List<Map<String, dynamic>> _promotions = [];
  bool _isLoading = true;
  
  // Carousel State
  final PageController _pageController = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_promotions.length < 2) return;
      
      if (_currentPage < _promotions.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchPromotions() async {
    try {
      final data = await SupabaseConfig.client
          .from('featured_promotions')
          .select()
          .eq('is_active', true)
          .order('priority', ascending: false);
      
      if (mounted) {
        setState(() {
          _promotions = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
        _startAutoPlay();
      }
    } catch (e) {
      debugPrint('Error fetching promotions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 156, // Adjusted height to match final
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_promotions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 140, 
          child: PageView.builder(
            controller: _pageController,
            padEnds: false, // Wait, PageView centers by default with viewportFraction. padEnds adds start/end padding. False means start from edge. Let's keep default behavior of viewportFraction which centers active item.
            // Actually default padEnds is true.
            itemCount: _promotions.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final promo = _promotions[index];
              final bgColorHex = promo['background_color'] ?? '0xFF6B2FBA';
              final color = Color(int.parse(bgColorHex));
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  image: promo['image_url'] != null 
                      ? DecorationImage(
                          image: NetworkImage(promo['image_url']),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                        ) 
                      : null,
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            promo['title'] ?? '',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 18,
                              shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (promo['subtitle'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              promo['subtitle'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9), 
                                fontSize: 12,
                                shadows: const [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Generic icon if no image
                    if (promo['image_url'] == null)
                      Icon(Icons.star, color: Colors.white.withOpacity(0.2), size: 60),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Dots Indicator
        if (_promotions.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_promotions.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[300],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
