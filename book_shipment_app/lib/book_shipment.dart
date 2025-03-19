import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:http/http.dart' as http;

class BookShipmentScreen extends StatefulWidget {
  @override
  _BookShipmentScreenState createState() => _BookShipmentScreenState();
}

class _BookShipmentScreenState extends State<BookShipmentScreen> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController deliveryController = TextEditingController();
  String? selectedCourier;
  double price = 0.0;
  bool isLoading = false;

  final List<String> couriers = ["Delhivery", "DTDC", "Bluedart"];
  final String apiUrl = "http://172.23.15.52:5000/getShippingRate"; // Change if needed

  Future<void> fetchShippingRate() async {
    if (selectedCourier == null || pickupController.text.isEmpty || deliveryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "courier": selectedCourier,
          "pickup": pickupController.text.trim(),
          "delivery": deliveryController.text.trim()
        }),
      );

      print("📩 API Response Status: ${response.statusCode}");
      print("📜 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📊 Parsed Data: $data");

        // Check if the price key exists in the response
        if (data.containsKey("price")) {
          setState(() {
            // Parse price correctly from string to double
            price = double.tryParse(data["price"].toString()) ?? 0.0;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Price data not found in the response"), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching price"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("❌ API Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect to the server"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "bookShipment",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
              color: Colors.black,
            ),
          ),
        ),
        automaticallyImplyLeading: false, // This removes the back button
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset('assets/Box.jpg', height: 200, width: 250, fit: BoxFit.cover),
            SizedBox(height: 16),

            // 📦 Container for Input Fields
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Column(
                        children: [
                          Icon(Icons.circle, color: Colors.green),
                          Dash(direction: Axis.vertical, length: 40, dashLength: 4, dashColor: Colors.grey),
                          Icon(Icons.location_on, color: Colors.red),
                        ],
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          children: [
                            buildTextField("Enter Pickup Pin Code", pickupController),
                            SizedBox(height: 10),
                            buildTextField("Enter Delivery Pin Code", deliveryController),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  Text("Select Courier", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: selectedCourier,
                    hint: Text("Choose a courier"),
                    items: couriers.map((courier) {
                      return DropdownMenuItem(value: courier, child: Text(courier));
                    }).toList(),
                    onChanged: (value) => setState(() => selectedCourier = value),
                  ),
                  SizedBox(height: 20),

                  Text(
                    isLoading ? "Fetching price..." : (price > 0 ? "Estimated Price: ₹$price" : "price: ₹0"),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isLoading ? null : fetchShippingRate,  // Disable while loading
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Calculate Price"),
                  ),
                  SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: price > 0 ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Proceeding to payment"), backgroundColor: Colors.green),
                      );
                    } : null,  // Disable if price is not calculated
                    child: Text("Proceed to Pay"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}
