import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/theme/app_design_system.dart';
import '../../data/repositories/facts_repository_impl.dart';
import '../../domain/entities/university_fact.dart';
import '../../domain/usecases/get_unlocked_facts.dart';
import '../../domain/usecases/try_unlock_fact.dart';
import '../../fact_unlock_notifier.dart';
import '../../../map/data/repositories/map_repository_impl.dart';
import '../../../map/domain/usecases/get_user_total_points.dart';
import '../widgets/fact_card.dart';
import '../widgets/facts_top_bar.dart';
import '../widgets/unlock_progress_card.dart';

class FactsView extends StatefulWidget {
  const FactsView({super.key});

  @override
  State<FactsView> createState() => _FactsViewState();
}

class _FactsViewState extends State<FactsView> {
  final _repo = FactsRepositoryImpl();
  final _mapRepo = MapRepositoryImpl();

  late final GetUnlockedFacts _getUnlockedFacts;
  late final TryUnlockFact _tryUnlockFact;
  late final GetUserTotalPoints _getUserTotalPoints;

  List<UniversityFact> _facts = [];
  int _visitCount = 0;
  int _userPoints = 0;
  bool _isLoading = true;
  String? _error;
  UniversityFact? _newlyUnlockedFact;

  @override
  void initState() {
    super.initState();
    _getUnlockedFacts = GetUnlockedFacts(_repo);
    _tryUnlockFact = TryUnlockFact(_repo);
    _getUserTotalPoints = GetUserTotalPoints(_mapRepo);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _newlyUnlockedFact = null;
    });

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _error = 'No hay sesión activa.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Try to unlock any pending facts based on current visit milestones
      final newFact = await _tryUnlockFact(userId);

      final [facts, visitCount, userPoints] = await Future.wait([
        _getUnlockedFacts(userId),
        _repo.getVisitCount(userId),
        _getUserTotalPoints(userId),
      ]);

      if (!mounted) return;
      setState(() {
        _facts = facts as List<UniversityFact>;
        _visitCount = visitCount as int;
        _userPoints = userPoints as int;
        _newlyUnlockedFact = newFact;
        _isLoading = false;
      });

      if (newFact != null) {
        FactUnlockNotifier.instance.notify(newFact);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.primaryMain,
      body: Column(
        children: [
          FactsTopBar(points: _userPoints),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryMain,
                      ),
                    )
                  : _error != null
                      ? _buildError()
                      : _buildContent(bottomPadding),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.s4),
            FilledButton(
              onPressed: _loadData,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryMain,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(double bottomPadding) {
    return RefreshIndicator(
      color: AppColors.primaryMain,
      onRefresh: _loadData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s4, bottom: AppSpacing.s2),
              child: UnlockProgressCard(
                visitCount: _visitCount,
                unlockedCount: _facts.length,
              ),
            ),
          ),
          if (_facts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.only(
                top: AppSpacing.s2,
                bottom: AppSpacing.s2,
              ),
              sliver: SliverList.builder(
                itemCount: _facts.length,
                itemBuilder: (context, index) => _AnimatedFactCard(
                  fact: _facts[index],
                  index: index,
                  isNew: _newlyUnlockedFact?.id == _facts[index].id,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 16 + bottomPadding),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s5),
            decoration: BoxDecoration(
              color: AppColors.primaryMain.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              size: 48,
              color: AppColors.primaryMain,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          const Text(
            '¡Explora y desbloquea!',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppTypography.fontSizeLg,
              fontWeight: AppTypography.weightBold,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          const Text(
            'Visita 5 puntos de interés en el mapa para desbloquear tu primer dato curioso sobre la UNAL.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppTypography.fontSizeSm,
              height: AppTypography.lineHeightRelaxed,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFactCard extends StatefulWidget {
  final UniversityFact fact;
  final int index;
  final bool isNew;

  const _AnimatedFactCard({
    required this.fact,
    required this.index,
    required this.isNew,
  });

  @override
  State<_AnimatedFactCard> createState() => _AnimatedFactCardState();
}

class _AnimatedFactCardState extends State<_AnimatedFactCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 60),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Stagger entry animation
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Stack(
          children: [
            FactCard(fact: widget.fact, index: widget.index),
            if (widget.isNew)
              Positioned(
                top: 14,
                right: 28,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.stateCompleted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    '¡Nuevo!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
