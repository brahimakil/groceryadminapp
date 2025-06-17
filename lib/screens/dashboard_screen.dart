import 'package:flutter/material.dart';
import 'package:grocery_admin_panel/themes/app_theme.dart';
import 'package:grocery_admin_panel/services/analytics_service.dart';
import 'package:grocery_admin_panel/widgets/header.dart';
import 'package:grocery_admin_panel/widgets/orders_list.dart';
import 'package:grocery_admin_panel/responsive.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/MenuController.dart' as grocery;
import '../inner_screens/all_orders_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final ScrollController _scrollController = ScrollController();
  
  Map<String, int> totalCounts = {'products': 0, 'orders': 0, 'categories': 0};
  Map<String, double> revenueData = {'total': 0, 'today': 0, 'week': 0, 'month': 0};
  List<Map<String, dynamic>> dailySales = [];
  List<Map<String, dynamic>> categoryDistribution = [];
  List<Map<String, dynamic>> orderStatusDistribution = [];
  List<Map<String, dynamic>> recentActivity = [];
  List<Map<String, dynamic>> topProducts = [];
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    
    try {
      final results = await Future.wait([
        _analyticsService.getTotalCounts(),
        _analyticsService.getRevenueData(),
        _analyticsService.getDailySales(),
        _analyticsService.getCategoryDistribution(),
        _analyticsService.getOrderStatusDistribution(),
        _analyticsService.getRecentActivity(),
        _analyticsService.getTopSellingProducts(),
      ]);
      
      setState(() {
        totalCounts = results[0] as Map<String, int>? ?? {'products': 0, 'orders': 0, 'categories': 0};
        revenueData = results[1] as Map<String, double>? ?? {'total': 0, 'today': 0, 'week': 0, 'month': 0};
        dailySales = results[2] as List<Map<String, dynamic>>? ?? [];
        categoryDistribution = results[3] as List<Map<String, dynamic>>? ?? [];
        orderStatusDistribution = results[4] as List<Map<String, dynamic>>? ?? [];
        recentActivity = results[5] as List<Map<String, dynamic>>? ?? [];
        topProducts = results[6] as List<Map<String, dynamic>>? ?? [];
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        // Set safe default values
        totalCounts = {'products': 0, 'orders': 0, 'categories': 0};
        revenueData = {'total': 0, 'today': 0, 'week': 0, 'month': 0};
        dailySales = [];
        categoryDistribution = [];
        orderStatusDistribution = [];
        recentActivity = [];
        topProducts = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Fixed Header
        Header(
          title: 'Dashboard',
          fct: () {
            context.read<grocery.GroceryMenuController>().controlDashboarkMenu();
          },
        ),
        // Scrollable Content
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(
                        Responsive.isMobile(context) 
                          ? AppTheme.spacingMd 
                          : AppTheme.spacingLg,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - 200,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome Section
                            _buildWelcomeSection(),
                            SizedBox(height: Responsive.isMobile(context) 
                              ? AppTheme.spacingLg 
                              : AppTheme.spacingXl),
                            
                            // KPI Cards
                            _buildKPICards(),
                            SizedBox(height: Responsive.isMobile(context) 
                              ? AppTheme.spacingLg 
                              : AppTheme.spacingXl),
                            
                            // Charts Section with Real Data
                            _buildChartsSection(),
                            SizedBox(height: Responsive.isMobile(context) 
                              ? AppTheme.spacingLg 
                              : AppTheme.spacingXl),
                            
                            // Bottom Section
                            _buildBottomSection(),
                            
                            // Extra padding at bottom
                            const SizedBox(height: AppTheme.spacingXl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        Responsive.isMobile(context) 
          ? AppTheme.spacingLg 
          : AppTheme.spacingXl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.shadowLg,
      ),
      child: Responsive(
        mobile: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeContent(),
            const SizedBox(height: AppTheme.spacingLg),
            _buildWelcomeIcon(),
          ],
        ),
        desktop: Row(
          children: [
            Expanded(child: _buildWelcomeContent()),
            _buildWelcomeIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back!',
          style: AppTheme.headlineLarge.copyWith(
            color: Colors.white,
            fontSize: Responsive.isMobile(context) ? 24 : 32,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          'Here\'s what\'s happening with your store today.',
          style: AppTheme.bodyLarge.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Responsive(
          mobile: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickStat(
                'Today\'s Revenue',
                '\$${NumberFormat('#,##0.00').format(revenueData['today'] ?? 0)}',
                Icons.trending_up,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _buildQuickStat(
                'This Week',
                '\$${NumberFormat('#,##0.00').format(revenueData['week'] ?? 0)}',
                Icons.calendar_today,
              ),
            ],
          ),
          desktop: Row(
            children: [
              _buildQuickStat(
                'Today\'s Revenue',
                '\$${NumberFormat('#,##0.00').format(revenueData['today'] ?? 0)}',
                Icons.trending_up,
              ),
              const SizedBox(width: AppTheme.spacingXl),
              _buildQuickStat(
                'This Week',
                '\$${NumberFormat('#,##0.00').format(revenueData['week'] ?? 0)}',
                Icons.calendar_today,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeIcon() {
    return Container(
      padding: EdgeInsets.all(
        Responsive.isMobile(context) 
          ? AppTheme.spacingLg 
          : AppTheme.spacingXl,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Icon(
        Icons.dashboard,
        size: Responsive.isMobile(context) ? 48 : 64,
        color: Colors.white,
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTheme.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICards() {
    return Responsive(
      mobile: Column(
        children: [
          _buildKPICard('Total Revenue', '\$${NumberFormat('#,##0.00').format(revenueData['total'] ?? 0)}', Icons.attach_money, AppTheme.successGradient, '+12.5%'),
          const SizedBox(height: AppTheme.spacingMd),
          _buildKPICard('Products', '${totalCounts['products'] ?? 0}', Icons.inventory_2, AppTheme.primaryGradient, '+5.2%'),
          const SizedBox(height: AppTheme.spacingMd),
          _buildKPICard('Orders', '${totalCounts['orders'] ?? 0}', Icons.shopping_bag, AppTheme.warningGradient, '+8.1%'),
          const SizedBox(height: AppTheme.spacingMd),
          _buildKPICard('Categories', '${totalCounts['categories'] ?? 0}', Icons.category, AppTheme.accentGradient, '+2.3%'),
        ],
      ),
      tablet: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.spacingMd,
        mainAxisSpacing: AppTheme.spacingMd,
        childAspectRatio: 2.8,
        children: [
          _buildKPICard('Total Revenue', '\$${NumberFormat('#,##0.00').format(revenueData['total'] ?? 0)}', Icons.attach_money, AppTheme.successGradient, '+12.5%'),
          _buildKPICard('Products', '${totalCounts['products'] ?? 0}', Icons.inventory_2, AppTheme.primaryGradient, '+5.2%'),
          _buildKPICard('Orders', '${totalCounts['orders'] ?? 0}', Icons.shopping_bag, AppTheme.warningGradient, '+8.1%'),
          _buildKPICard('Categories', '${totalCounts['categories'] ?? 0}', Icons.category, AppTheme.accentGradient, '+2.3%'),
        ],
      ),
      desktop: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: AppTheme.spacingLg,
        mainAxisSpacing: AppTheme.spacingLg,
        childAspectRatio: 2.0,
        children: [
          _buildKPICard('Total Revenue', '\$${NumberFormat('#,##0.00').format(revenueData['total'] ?? 0)}', Icons.attach_money, AppTheme.successGradient, '+12.5%'),
          _buildKPICard('Products', '${totalCounts['products'] ?? 0}', Icons.inventory_2, AppTheme.primaryGradient, '+5.2%'),
          _buildKPICard('Orders', '${totalCounts['orders'] ?? 0}', Icons.shopping_bag, AppTheme.warningGradient, '+8.1%'),
          _buildKPICard('Categories', '${totalCounts['categories'] ?? 0}', Icons.category, AppTheme.accentGradient, '+2.3%'),
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, LinearGradient gradient, String trend) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  trend,
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Flexible(
            child: Text(
              value,
              style: AppTheme.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.isMobile(context) ? 18 : 22,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Flexible(
            child: Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: Responsive.isMobile(context) ? 12 : 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      children: [
        // Line Chart - Sales Over Time
        _buildSalesLineChart(),
        const SizedBox(height: AppTheme.spacingLg),
        
        // Row with Bar Chart and Pie Chart
        Responsive(
          mobile: Column(
            children: [
              _buildRevenueBarChart(),
              const SizedBox(height: AppTheme.spacingLg),
              _buildCategoryPieChart(),
            ],
          ),
          desktop: Row(
            children: [
              Expanded(child: _buildRevenueBarChart()),
              const SizedBox(width: AppTheme.spacingLg),
              Expanded(child: _buildCategoryPieChart()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesLineChart() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sales Trend (Last 7 Days)',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  'Real Data',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            height: 300,
            child: dailySales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 48,
                          color: AppTheme.neutral400,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          'No sales data available',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Theme.of(context).dividerColor,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value.toInt() < dailySales.length) {
                                final dateStr = dailySales[value.toInt()]['date']?.toString() ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    dateStr,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                '\$${value.toInt()}',
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                            reservedSize: 42,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (dailySales.length - 1).toDouble(),
                      minY: 0,
                      maxY: dailySales.isEmpty 
                          ? 100 
                          : dailySales.map((e) => (e['revenue'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b) * 1.2,
                      lineBarsData: [
                        LineChartBarData(
                          spots: dailySales.asMap().entries.map((entry) {
                            final revenue = (entry.value['revenue'] as num?)?.toDouble() ?? 0;
                            return FlSpot(entry.key.toDouble(), revenue);
                          }).toList(),
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.3),
                            ],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppTheme.primaryColor,
                                strokeWidth: 2,
                                strokeColor: Theme.of(context).cardColor,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.3),
                                AppTheme.primaryColor.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBarChart() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Revenue Distribution',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            height: 300,
            child: dailySales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 48,
                          color: AppTheme.neutral400,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          'No revenue data available',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: dailySales.isEmpty 
                          ? 100 
                          : dailySales.map((e) => (e['revenue'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b) * 1.2,
                      barTouchData: BarTouchData(
                        enabled: false,
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value.toInt() < dailySales.length) {
                                final dateStr = dailySales[value.toInt()]['date']?.toString() ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    dateStr,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                '\$${value.toInt()}',
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: dailySales.asMap().entries.map((entry) {
                        final revenue = (entry.value['revenue'] as num?)?.toDouble() ?? 0;
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: revenue,
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppTheme.warningColor,
                                  AppTheme.warningColor.withOpacity(0.7),
                                ],
                              ),
                              width: 16,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    // Generate a wider palette of colors for categories
    final List<Color> categoryColors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.warningColor,
      AppTheme.successColor,
      AppTheme.errorColor,
      AppTheme.accentColor,
      AppTheme.infoColor,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.deepOrange,
      Colors.indigo,
      Colors.lime,
      Colors.lightBlue,
      Colors.pink.shade300,
      Colors.green.shade300,
    ];

    // Debug: Print category distribution data
    print('Category Distribution Data: $categoryDistribution');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Categories',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            height: 300,
            child: categoryDistribution.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pie_chart,
                          size: 48,
                          color: AppTheme.neutral400,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          'No category data available',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: PieChart(
                          PieChartData(
                            sections: categoryDistribution.map((category) {
                              final index = categoryDistribution.indexOf(category);
                              final categoryName = (category['name'] as String?) ?? 'Unknown';
                              final count = (category['count'] as num?)?.toInt() ?? 0;
                              
                              print('Creating section for category: $categoryName with count: $count');
                              
                              return PieChartSectionData(
                                color: categoryColors[index % categoryColors.length],
                                value: count.toDouble(),
                                title: '$count',
                                titleStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                radius: 60,
                                showTitle: true,
                                borderSide: const BorderSide(width: 1, color: Colors.white),
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            pieTouchData: PieTouchData(
                              enabled: true,
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                if (event.isInterestedForInteractions &&
                                    pieTouchResponse != null &&
                                    pieTouchResponse.touchedSection != null) {
                                  final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  if (touchedIndex >= 0 && touchedIndex < categoryDistribution.length) {
                                    final category = categoryDistribution[touchedIndex];
                                    print('Touched category: ${category['name']} with ${category['count']} products');
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (categoryDistribution.isEmpty)
                                Text(
                                  'Loading categories...',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.neutral500,
                                  ),
                                )
                              else
                                ...categoryDistribution.map((category) {
                                  final index = categoryDistribution.indexOf(category);
                                  final categoryName = (category['name'] as String?) ?? 'Unknown';
                                  final count = (category['count'] as num?)?.toInt() ?? 0;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: categoryColors[index % categoryColors.length],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: AppTheme.spacingSm),
                                        Expanded(
                                          child: Text(
                                            categoryName,
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ),
                                        Text(
                                          '$count products',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Responsive(
      mobile: Column(
        children: [
          _buildRecentOrdersCard(),
          const SizedBox(height: AppTheme.spacingLg),
          _buildRecentActivityCard(),
        ],
      ),
      desktop: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildRecentOrdersCard()),
          const SizedBox(width: AppTheme.spacingLg),
          Expanded(child: _buildRecentActivityCard()),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Orders',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllOrdersScreen(),
                    ),
                  );
                },
                child: Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          OrdersList(
            isInDashboard: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          recentActivity.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: AppTheme.neutral400,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        'No recent activity',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.neutral500,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: recentActivity.map((activity) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Icon(
                            Icons.shopping_bag,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (activity['title'] as String?) ?? 'Activity',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                (activity['subtitle'] as String?) ?? 'Description',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.neutral500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          (activity['time'] as String?) ?? 'Now',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.neutral500,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
        ],
      ),
    );
  }
}
