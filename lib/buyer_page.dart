// buyer_page.dart

import 'package:flutter/material.dart';
import 'database_helper.dart';

class BuyerPage extends StatefulWidget {
  @override
  _BuyerPageState createState() => _BuyerPageState();
}

class _BuyerPageState extends State<BuyerPage> {
  final _regionController = TextEditingController();
  List<Map<String, dynamic>> _products = [];

  Future<void> _fetchProducts() async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    final products = await dbHelper.getProductsByRegion(_regionController.text);
    setState(() {
      _products = products;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Products'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue, Colors.green],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue, Colors.green],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _regionController,
                decoration: InputDecoration(
                  labelText: 'Enter Region',
                  border: OutlineInputBorder(), // Style as box
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchProducts,
                child: Text('View Products'),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue, Colors.green],
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: ListTile(
                          title: Text(product['product']),
                          subtitle: Text('Price: ${product['price']}'),
                          trailing: Text('Region: ${product['region']}'),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
