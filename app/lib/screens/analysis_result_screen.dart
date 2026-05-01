import 'package:flutter/material.dart';
import '../services/history_service.dart';
import 'package:intl/intl.dart';

class AnalysisResultScreen extends StatelessWidget {
  final List<String> labels;
  final double confidence;

  const AnalysisResultScreen({
    Key? key,
    required this.labels,
    required this.confidence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Analysis Complete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/home_bg.png',
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.5),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildConfidenceMetric(),
                const SizedBox(height: 30),
                const Text(
                  'Your Palm Interpretation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'The universe has spoken through the lines of your hand. Here is what we found:',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ...labels.map((label) => _buildResultCard(label)).toList(),
                const SizedBox(height: 40),
                _buildActionButtons(context),
                const SizedBox(height: 60),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceMetric() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Confidence',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                '${(confidence * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: confidence,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String label) {
    // Generate a detailed description based on the label
    String description = "The lines in your palm indicate a strong presence of this trait, suggesting a path filled with potential and energy.";
    if (label.contains("Vitality")) {
      description = "Your Life Line shows a deep, continuous path, suggesting high physical energy and a resilient spirit that overcomes obstacles easily.";
    } else if (label.contains("Thinking")) {
      description = "The clarity of your Head Line reflects an analytical mind with the ability to focus on complex problems and reach logical conclusions.";
    } else if (label.contains("Idealism")) {
      description = "A well-defined Heart Line suggests a person who values emotional connections and views the world through a lens of compassion and empathy.";
    } else if (label.contains("Driven")) {
      description = "Your Fate Line indicates a strong sense of purpose and a career path that is defined by your own hard work and determination.";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () async {
              final record = AnalysisRecord(
                date: DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.now()),
                labels: labels,
                confidence: confidence,
              );
              await HistoryService().saveAnalysis(record);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analysis saved to history!')),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('SAVE TO HISTORY', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'DISCARD AND RETRY',
            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
