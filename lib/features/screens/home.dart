import 'package:flutter/material.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Map<String, dynamic>> skills = [
    {"name": "flutter", "score": 10, "habits": ["learn", "build"]},
    {"name": "JS", "score": 30, "habits": ["watch", "practice"]},
  ];

  Set<int> expandedIndices = {};
  Map<String, Set<String>> selectedHabits = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skills')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: skills.length,
              itemBuilder: (context, index) {
                final skill = skills[index];
                final isExpanded = expandedIndices.contains(index);
                final habitSelections = selectedHabits[skill['name']] ?? {};
            
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text('${skill["name"]}'),
                      subtitle: Text('Score: ${skill["score"]}'),
                      trailing: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            expandedIndices.remove(index);
                          } else {
                            expandedIndices.add(index);
                          }
                        });
                      },
                    ),
                    if (isExpanded) ...[
                      ...skill['habits'].map<Widget>((habit) {
                        final isChecked = habitSelections.contains(habit);
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: CheckboxListTile(
                            title: Text(habit),
                            value: isChecked,
                            onChanged: (value) {
                              setState(() {
                                final selected = selectedHabits[skill['name']] ?? {};
                                if (value == true) {
                                  selected.add(habit);
                                } else {
                                  selected.remove(habit);
                                }
                                selectedHabits[skill['name']] = selected;
                              });
                            },
                          ),
                        );
                      }).toList(),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Button tapped for ${skill["name"]}'),
                            ));
                          },
                          child: const Text('Do something'),
                        ),
                      ),
                    ],
                    const Divider(),
                    
                  ],
                );
              },
            ),
          ),
          ElevatedButton(onPressed: () {Navigator.of(context).pushNamed('/add_skill');}, child: const Text('Add New Skill')),
        ],
      ),
    );
  }
}
