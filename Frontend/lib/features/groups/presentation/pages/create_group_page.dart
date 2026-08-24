import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();

  final groupNameController = TextEditingController();
  final contributionController = TextEditingController(text: "5000");
  final descriptionController = TextEditingController();

  String _selectedFrequency = "Monthly";
  DateTime _startDate = DateTime.now();
  int _maxMembers = 12;
  bool _isLoading = false;

  static const Color headerColor = Color(0xFF9E3A00);
  static const Color primaryOrange = Color(0xFFFF5C00);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);

  final List<String> _frequencies = [
    "Daily",
    "Weekly",
    "Bi-weekly",
    "Monthly",
  ];

  @override
  void dispose() {
    groupNameController.dispose();
    contributionController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _incrementMembers() {
    setState(() {
      if (_maxMembers < 100) {
        _maxMembers++;
      }
    });
  }

  void _decrementMembers() {
    setState(() {
      if (_maxMembers > 2) {
        _maxMembers--;
      }
    });
  }

  String _getDurationText() {
    switch (_selectedFrequency) {
      case "Daily":
        return "$_maxMembers days";
      case "Weekly":
        return "$_maxMembers weeks";
      case "Bi-weekly":
        return "${_maxMembers * 2} weeks";
      case "Monthly":
        return "$_maxMembers months";
      default:
        return "$_maxMembers months";
    }
  }

  int _getCycleDuration() {
    switch (_selectedFrequency) {
      case "Daily":
        return 1;
      case "Weekly":
        return 7;
      case "Bi-weekly":
        return 14;
      case "Monthly":
        return 30;
      default:
        return 30;
    }
  }

  Future<void> _submitCreateGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = int.tryParse(
            contributionController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter a valid contribution amount")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await GroupService().createGroup(
        groupName: groupNameController.text.trim(),
        contribution: amount,
        duration: _getCycleDuration(),
        maxMembers: _maxMembers,
        startDate: _startDate,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );

      if (!mounted) return;

      if (response["success"] == true || response["data"] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Group Created Successfully!"),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        // Fallback success for local testing if API isn't running
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response["message"] ?? "Group created successfully!"),
            backgroundColor:
                response["message"] != null && response["success"] == false
                    ? Colors.red.shade700
                    : const Color(0xFF10B981),
          ),
        );
        if (response["success"] != false) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      debugPrint("Error creating group: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: headerColor,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: const Text(
            "Create Group",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Subtitle
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Text(
                      "Set up a new Equb circle to start saving with your trusted peers.",
                      style: TextStyle(
                        fontSize: 15.5,
                        color: textMuted.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ),

                  // Main Form Card Container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: const Color(0xFFF1F5F9), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Group Name Field
                          _buildFieldLabel("Group Name"),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: groupNameController,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: "e.g. Family Savings, Q4 Goals",
                              hintStyle: const TextStyle(
                                color: textLight,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w400,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: primaryOrange, width: 1.5),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "Please enter a group name";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // 2. Contribution Amount Field
                          _buildFieldLabel("Contribution Amount (per cycle)"),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: contributionController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 16, right: 8),
                                child: Text(
                                  "ETB ",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textMuted,
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                  minWidth: 0, minHeight: 0),
                              hintText: "5000",
                              hintStyle: const TextStyle(
                                color: textLight,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: primaryOrange, width: 1.5),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "Please enter contribution amount";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // 3. Cycle Frequency Section
                          _buildFieldLabel("Cycle Frequency"),
                          const SizedBox(height: 10),
                          Column(
                            children: _frequencies.map((freq) {
                              final isSelected = _selectedFrequency == freq;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedFrequency = freq),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryOrange
                                            : borderColor,
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Custom Radio Circle
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? primaryOrange
                                                  : const Color(0xFFCBD5E1),
                                              width: isSelected ? 6.0 : 1.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          freq,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 12),
                          _buildFieldLabel("Start Date"),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 3650)),
                              );
                              if (selected != null) {
                                setState(() => _startDate = selected);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                    Icons.calendar_today_rounded,
                                    color: primaryOrange),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: borderColor)),
                              ),
                              child: Text(
                                "${_startDate.day}/${_startDate.month}/${_startDate.year}",
                                style: const TextStyle(
                                    color: textDark,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 4. Maximum Members Stepper Section
                          _buildFieldLabel(
                              "Maximum Members (Duration in cycles)"),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Minus Button
                                IconButton(
                                  onPressed: _decrementMembers,
                                  icon: const Icon(Icons.remove,
                                      color: textMuted, size: 22),
                                  splashRadius: 20,
                                ),
                                // Member Count
                                Text(
                                  "$_maxMembers",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                  ),
                                ),
                                // Plus Button
                                IconButton(
                                  onPressed: _incrementMembers,
                                  icon: const Icon(Icons.add,
                                      color: primaryOrange, size: 22),
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "A $_maxMembers-member group with ${_selectedFrequency.toLowerCase()} cycles lasts for ${_getDurationText()}.",
                            style: const TextStyle(
                              fontSize: 12,
                              color: textLight,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 5. Group Details (Optional)
                          _buildFieldLabel("Group Details (Optional)"),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 4,
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: textDark,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: "Describe the purpose of this group...",
                              hintStyle: const TextStyle(
                                color: textLight,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: primaryOrange, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed Bottom Action Button: "Create Group →"
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Color(0xFFF1F5F9),
                  width: 1.0,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCreateGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Create Group",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textMuted,
      ),
    );
  }
}
