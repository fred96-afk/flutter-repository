import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polleria Gigante'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/polleria.png',
              width: 200,
              height: 200,
            ), // Asegúrate de tener la imagen en la carpeta 'assets/images/'
            SizedBox(height: 20),
            Text('Bienvenido a', style: TextStyle(fontSize: 24)),
            SizedBox(height: 10),
            Text(
              'Polleria Gigante',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Aquí iría la lógica para manejar el clic del botón
              },
              child: Text('Pedir Ahora'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
