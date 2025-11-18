import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:beta_caller/providers/call_provider.dart';
import 'package:beta_caller/models/call_model.dart';
import 'package:beta_caller/utils/app_theme.dart';
import 'dart:async';
import 'dart:ui';

class CallingScreen extends StatefulWidget {
  final String phoneNumber;
  final String contactName;

  const CallingScreen({
    super.key,
    required this.phoneNumber,
    required this.contactName,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> with TickerProviderStateMixin {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _showKeypad = false;
  Timer? _callTimer;
  int _callDuration = 0;

  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Call after the first frame is built to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiateCall();
    });
  }

  Future<void> _initiateCall() async {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    await callProvider.makeCall(widget.phoneNumber, widget.contactName);

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
        final callProvider = Provider.of<CallProvider>(context, listen: false);
        callProvider.updateCallDuration(_callDuration);
      }
    });

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final callProvider = Provider.of<CallProvider>(context, listen: false);
      callProvider.updateCallStatus(CallStatus.connected);
      _pulseController.stop();
      _rippleController.stop();
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseController.dispose();
    _rippleController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  Future<void> _endCall() async {
    _callTimer?.cancel();
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    await callProvider.endCall();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
  }

  void _toggleKeypad() {
    setState(() {
      _showKeypad = !_showKeypad;
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A0000),
              const Color(0xFF0A0E27),
              const Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<CallProvider>(
            builder: (context, callProvider, _) {
              final activeCall = callProvider.activeCall;
              final callStatus = activeCall?.callStatus ?? CallStatus.connecting;

              return SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Avatar with ripples
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ripple effects (only when connecting/ringing)
                              if (callStatus == CallStatus.connecting ||
                                  callStatus == CallStatus.ringing) ...[
                                AnimatedBuilder(
                                  animation: _rippleAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: 1 + (_rippleAnimation.value * 0.5),
                                      child: Container(
                                        width: 180,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              (1 - _rippleAnimation.value) * 0.3,
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                AnimatedBuilder(
                                  animation: _rippleAnimation,
                                  builder: (context, child) {
                                    final delayed = (_rippleAnimation.value + 0.5) % 1.0;
                                    return Transform.scale(
                                      scale: 1 + (delayed * 0.5),
                                      child: Container(
                                        width: 180,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              (1 - delayed) * 0.3,
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],

                              // Main avatar
                              if (callStatus == CallStatus.connecting ||
                                  callStatus == CallStatus.ringing)
                                ScaleTransition(
                                  scale: _pulseAnimation,
                                  child: _buildMainAvatar(),
                                )
                              else
                                _buildMainAvatar(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Contact name
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            widget.contactName,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Phone number
                        Text(
                          widget.phoneNumber,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 1,
                          ),
                        ),

                    const SizedBox(height: 16),

                    // Status/Duration
                    if (callStatus == CallStatus.connected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          _formatDuration(_callDuration),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      )
                    else
                      Text(
                        _getStatusText(callStatus),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                      ),

                    const Spacer(),

                    // Bottom controls section
                    if (callStatus == CallStatus.connected)
                      if (_showKeypad)
                        _buildKeypadView()
                      else
                        _buildControlButtons()
                    else
                      // Show placeholder space when not connected to maintain layout
                      const SizedBox(height: 120),

                    const SizedBox(height: 30),

                    // End call button - always visible
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: GestureDetector(
                        onTap: _endCall,
                        child: Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF3B30).withOpacity(0.5),
                                blurRadius: 25,
                                spreadRadius: 0,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainAvatar() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.accentColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 70,
        color: Colors.white,
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: 'mute',
                isActive: _isMuted,
                onTap: _toggleMute,
              ),
              _buildControlButton(
                icon: Icons.dialpad_rounded,
                label: 'keypad',
                isActive: _showKeypad,
                onTap: _toggleKeypad,
              ),
              _buildControlButton(
                icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                label: 'speaker',
                isActive: _isSpeakerOn,
                onTap: _toggleSpeaker,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.person_add_rounded,
                label: 'add call',
                onTap: () {},
              ),
              _buildControlButton(
                icon: Icons.videocam_rounded,
                label: 'video',
                onTap: () {},
              ),
              _buildControlButton(
                icon: Icons.contacts_rounded,
                label: 'contacts',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                width: isActive ? 0 : 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF0A0E27) : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Keypad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: _toggleKeypad,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildKeypadGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadGrid() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              return _buildKeypadButton(key);
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText(CallStatus status) {
    switch (status) {
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Call Ended';
      case CallStatus.failed:
        return 'Call Failed';
      case CallStatus.rejected:
        return 'Call Rejected';
    }
  }
}
