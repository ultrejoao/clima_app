import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _cityController = TextEditingController();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _showSearch = true;

  static const String apiKey = '4800d89c6b737e953d8e48e15d9dda15';

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _weatherData = null;
    });

    try {
      final city = _cityController.text.trim();
      if (city.isEmpty) {
        throw Exception('Por favor, digite o nome da cidade');
      }

      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=${Uri.encodeComponent(city)}&appid=$apiKey&units=metric&lang=pt_br'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body);
        });
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao buscar dados da cidade');
      }
    } on http.ClientException catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão: ${e.message}';
      });
    } on Exception catch (e) {
      String message;
      if (e.toString().contains('TimeoutException')) {
        message = 'Tempo de espera esgotado';
      } else if (e.toString().contains('404')) {
        message = 'Cidade não encontrada';
      } else if (e.toString().contains('401')) {
        message = 'Chave API inválida';
      } else {
        message = 'Erro: ${e.toString()}';
      }
      setState(() {
        _errorMessage = message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDayTime = _weatherData != null 
        ? DateTime.now().hour > 6 && DateTime.now().hour < 18
        : true;

    return Scaffold(
      backgroundColor: isDayTime ? Colors.blue[50] : Colors.indigo[900],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_showSearch) _buildSearchBar(),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Text(
                    _errorMessage,
                    style: GoogleFonts.lato(
                      color: Colors.red[700],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (_weatherData != null)
                _buildWeatherCard(isDayTime)
              else
                _buildWelcomeMessage(isDayTime),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showSearch = !_showSearch;
          });
        },
        backgroundColor: isDayTime ? Colors.blue : Colors.indigo[700],
        child: Icon(
          _showSearch ? Icons.close : Icons.search,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    hintText: 'Digite a cidade...',
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.lato(),
                  ),
                  style: GoogleFonts.lato(),
                  onSubmitted: (_) => _fetchWeatherData(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _fetchWeatherData,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage(bool isDayTime) {
    return Padding(
      padding: const EdgeInsets.only(top: 150),
      child: Column(
        children: [
          Icon(
            Icons.cloud,
            size: 100,
            color: isDayTime ? Colors.blue[400] : Colors.white,
          ),
          const SizedBox(height: 20),
          Text(
            'ClimaApp',
            style: GoogleFonts.lato(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDayTime ? Colors.black87 : Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Digite uma cidade para ver\nas condições climáticas',
            style: GoogleFonts.lato(
              fontSize: 18,
              color: isDayTime ? Colors.black54 : Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(bool isDayTime) {
    final weather = _weatherData!['weather'][0];
    final main = _weatherData!['main'];
    final sys = _weatherData!['sys'];
    final wind = _weatherData!['wind'];
    final dt = DateTime.fromMillisecondsSinceEpoch(_weatherData!['dt'] * 1000);
    final sunrise = DateTime.fromMillisecondsSinceEpoch(sys['sunrise'] * 1000);
    final sunset = DateTime.fromMillisecondsSinceEpoch(sys['sunset'] * 1000);

    final icon = _getWeatherIcon(weather['id'], dt.hour);

    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          '${_weatherData!['name']}, ${sys['country']}',
          style: GoogleFonts.lato(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDayTime ? Colors.black87 : Colors.white,
          ),
        ),
        Text(
          DateFormat('EEEE, d MMMM').format(dt),
          style: GoogleFonts.lato(
            fontSize: 16,
            color: isDayTime ? Colors.black54 : Colors.white70,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDayTime ? Colors.white : Colors.indigo[800],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 80,
                    color: isDayTime ? Colors.amber : Colors.yellow[200],
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${main['temp'].round()}°C',
                        style: GoogleFonts.lato(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: isDayTime ? Colors.black87 : Colors.white,
                        ),
                      ),
                      Text(
                        '${weather['description'][0].toUpperCase()}${weather['description'].substring(1)}',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          color: isDayTime ? Colors.black54 : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: isDayTime ? Colors.grey[300] : Colors.indigo[600]),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherDetail(
                    'Sensação',
                    '${main['feels_like'].round()}°C',
                    Icons.thermostat,
                    isDayTime,
                  ),
                  _buildWeatherDetail(
                    'Umidade',
                    '${main['humidity']}%',
                    Icons.water_drop,
                    isDayTime,
                  ),
                  _buildWeatherDetail(
                    'Vento',
                    '${wind['speed']} m/s',
                    Icons.air,
                    isDayTime,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherDetail(
                    'Nascer do sol',
                    DateFormat('HH:mm').format(sunrise),
                    Icons.wb_sunny,
                    isDayTime,
                  ),
                  _buildWeatherDetail(
                    'Pôr do sol',
                    DateFormat('HH:mm').format(sunset),
                    Icons.nightlight,
                    isDayTime,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon, bool isDayTime) {
    return Column(
      children: [
        Icon(
          icon,
          size: 30,
          color: isDayTime ? Colors.blue[400] : Colors.blue[200],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 14,
            color: isDayTime ? Colors.black54 : Colors.white70,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDayTime ? Colors.black87 : Colors.white,
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(int condition, int hour) {
    if (condition < 300) return Icons.electric_bolt; 
    if (condition < 400) return Icons.beach_access; 
    if (condition < 600) return Icons.umbrella; 
    if (condition < 700) return Icons.ac_unit; 
    if (condition == 800) return hour > 6 && hour < 20 
        ? Icons.wb_sunny 
        : Icons.nightlight_round; 
    return Icons.cloud; 
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }
}