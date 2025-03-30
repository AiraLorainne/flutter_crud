// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'user_model.dart';
import 'api_service.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  UserScreenState createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  late Future<List<User>> futureUsers;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  int? editingId;

  @override
  void initState() {
    super.initState();
    futureUsers = ApiService.getUsers();
  }

  void refreshUsers() {
    setState(() {
      futureUsers = ApiService.getUsers();
    });
  }

  void handleSave() async {
    String name = nameController.text;
    String email = emailController.text;

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Name and email cannot be empty")));
      return;
    }

    if (editingId == null) {
      await ApiService.addUser(name, email); // Add new user
    } else {
      bool success = await ApiService.updateUser(
        editingId!,
        name,
        email,
      ); // Update user
      if (!success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update user")));
        return;
      }
    }

    nameController.clear();
    emailController.clear();
    editingId = null;
    refreshUsers();
    Navigator.pop(context); // Close the dialog after saving
  }

  void handleEdit(User user) {
    setState(() {
      nameController.text = user.name;
      emailController.text = user.email;
      editingId = user.id;
    });
    showUserDialog();
  }

  void handleDelete(int id) async {
    await ApiService.deleteUser(id);
    refreshUsers();
  }

  void showUserDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(editingId == null ? "Add User" : "Edit User"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: handleSave,
                child: Text(editingId == null ? "Add" : "Update"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Flutter CRUD with Express",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey,
      ),
      body: FutureBuilder<List<User>>(
        future: futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No Users Found"));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              User user = snapshot.data![index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 5,
                child: ListTile(
                  title: Text(
                    user.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => handleEdit(user),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => handleDelete(user.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showUserDialog,
        backgroundColor: const Color.fromARGB(255, 43, 42, 42),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
