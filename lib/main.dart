import 'package:flutter/material.dart';

void main() {
  runApp(RecipeApp());
}

class RecipeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '菜谱工具',
      theme: ThemeData(useMaterial3: true),
      home: RecipeTool(),
    );
  }
}

class RecipeTool extends StatefulWidget {
  @override
  _RecipeToolState createState() => _RecipeToolState();
}

class _RecipeToolState extends State<RecipeTool> {
  List<Map<String, dynamic>> ingredients = [
    {'name': '主料', 'weight': 0.0}
  ];

  bool isLocked = false;
  Map<String, double> standardProportions = {};

  List<String> ingredientOptions = [
    '主料', '盐', '糖', '油', '老抽', '生抽', '料酒', '淀粉', '水', '葱', '姜', '蒜',
    '辣椒', '花椒', '八角', '其它'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("菜谱工具")),
      body: ListView.builder(
        itemCount: ingredients.length + 1,
        itemBuilder: (context, index) {
          if (index == ingredients.length) {
            return Center(
              child: ElevatedButton(
                onPressed: isLocked
                    ? null
                    : () {
                        setState(() {
                          ingredients.add({'name': '主料', 'weight': 0.0});
                        });
                      },
                child: Text("添加食材"),
              ),
            );
          } else {
            return _buildIngredientCard(index);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleLock,
        child: Icon(isLocked ? Icons.lock : Icons.lock_open),
      ),
    );
  }

  Widget _buildIngredientCard(int index) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 食材名称
            Expanded(
              flex: 2,
              child: DropdownButton<String>(
                value: ingredientOptions.contains(ingredients[index]['name'])
                    ? ingredients[index]['name']
                    : '其它',  // 处理自定义食材
                items: ingredientOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: isLocked
                    ? null
                    : (value) {
                        if (value == '其它') {
                          _showCustomIngredientDialog(index);
                        } else {
                          setState(() {
                            ingredients[index]['name'] = value!;
                          });
                        }
                      },
              ),
            ),
            // 减少按钮
            IconButton(
              onPressed: ingredients[index]['weight'] == 0
                  ? null
                  : () {
                      setState(() {
                        ingredients[index]['weight'] =
                            (ingredients[index]['weight'] - 1).clamp(0.0, double.infinity);
                        _updateWeights(index);
                      });
                    },
              icon: Icon(Icons.remove),
            ),
            // 食材重量
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () async {
                  double? newWeight = await _showWeightInputDialog(index);
                  if (newWeight != null) {
                    setState(() {
                      ingredients[index]['weight'] = newWeight;
                      _updateWeights(index);
                    });
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${ingredients[index]['weight'].toStringAsFixed(1)}g',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            ),
            // 增加按钮
            IconButton(
              onPressed: () {
                setState(() {
                  ingredients[index]['weight'] += 1;
                  _updateWeights(index);
                });
              },
              icon: Icon(Icons.add),
            ),
            // 删除按钮
            IconButton(
              onPressed: isLocked
                  ? null
                  : () {
                      _removeIngredientWithUndo(index);
                    },
              icon: Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLock() {
    setState(() {
      isLocked = !isLocked;
      if (isLocked) {
        // 保存当前的标准比例
        standardProportions = Map.fromEntries(
          ingredients.map((ingredient) => MapEntry(
              ingredient['name'], ingredient['weight'])),
        );
      }
    });
  }

  void _updateWeights(int changedIndex) {
    if (isLocked) {
      double factor = ingredients[changedIndex]['weight'] /
          standardProportions[ingredients[changedIndex]['name']]!;
      setState(() {
        for (int i = 0; i < ingredients.length; i++) {
          if (i != changedIndex) {
            ingredients[i]['weight'] =
                (standardProportions[ingredients[i]['name']]! * factor);
          }
        }
      });
    }
  }

  Future<void> _showCustomIngredientDialog(int index) async {
    TextEditingController controller = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('输入食材名称'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "输入食材"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定'),
              onPressed: () {
                setState(() {
                  String customIngredient = controller.text;
                  // 将自定义食材加入选项列表
                  ingredientOptions.add(customIngredient);
                  ingredients[index]['name'] = customIngredient;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<double?> _showWeightInputDialog(int index) async {
    TextEditingController controller = TextEditingController();
    controller.text = ingredients[index]['weight'].toStringAsFixed(1);

    return showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('输入重量'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(suffixText: "g"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定'),
              onPressed: () {
                double? newWeight = double.tryParse(controller.text);
                if (newWeight != null) {
                  Navigator.of(context).pop(newWeight);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _removeIngredientWithUndo(int index) {
    var removedIngredient = ingredients[index];
    setState(() {
      ingredients.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("食材已删除"),
        action: SnackBarAction(
          label: "撤销",
          onPressed: () {
            setState(() {
              ingredients.insert(index, removedIngredient);
            });
          },
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }
}
