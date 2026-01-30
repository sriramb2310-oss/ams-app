import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(AMSApp());

class AMSApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMS',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: MainDashboard(),
      routes: { '/complaints': (context) => ComplaintsPage() },
    );
  }
}

// Maintenance Categories [file:52]
const List<String> maintenanceCategories = [
  'Repair & renovation', 'Painting', 'Plumbing', 'Electrical',
  'Common area cleaning', 'Sewage tank cleaning', 'Water charges',
  'Generator fuel & maintenance', 'Lift/elevator electricity',
  'Security guard salary', 'Housekeeping staff salary', 'Lift maintenance',
  'CCTV/Intercom maintenance', 'Accounting software charges',
  'Building structural work', 'Others',
];

// Expense Types [file:63]
const List<String> expenseTypes = ['Common', 'Individual'];

// Unified Data Model
class AppData {
  List<Transaction> transactions = [];
  List<Complaint> complaints = [];
  AppData();
  factory AppData.fromJson(Map<String, dynamic> json) {
    final data = AppData();
    data.transactions = (json['transactions'] as List<dynamic>? ?? [])
        .map((t) => Transaction.fromJson(t)).toList();
    data.complaints = (json['complaints'] as List<dynamic>? ?? [])
        .map((c) => Complaint.fromJson(c)).toList();
    return data;
  }
  Map<String, dynamic> toJson() => {
    'transactions': transactions.map((t) => t.toJson()).toList(),
    'complaints': complaints.map((c) => c.toJson()).toList(),
  };
}

class Transaction {
  String id, title, date, category, type;
  double amount;
  Transaction({required this.id, required this.title, required this.date, required this.amount, required this.category, required this.type});
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'], title: json['title'], date: json['date'],
    amount: double.parse(json['amount'].toString()), category: json['category'], type: json['type'],
  );
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'date': date, 'amount': amount, 'category': category, 'type': type};
}

class Complaint {
  String id, title, status, priority, date, assignedTo, workSummary, expenseType;
  double resolutionCost;
  Complaint({
    required this.id, required this.title, required this.status, required this.priority,
    required this.date, required this.assignedTo, required this.workSummary,
    required this.expenseType, required this.resolutionCost,
  });
  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
    id: json['id'], title: json['title'], status: json['status'] ?? 'Pending',
    priority: json['priority'], date: json['date'], assignedTo: json['assignedTo'],
    workSummary: json['workSummary'] ?? '', expenseType: json['expenseType'] ?? 'Common',
    resolutionCost: double.tryParse(json['resolutionCost'].toString()) ?? 0.0,
  );
  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'status': status, 'priority': priority, 'date': date,
    'assignedTo': assignedTo, 'workSummary': workSummary, 'expenseType': expenseType,
    'resolutionCost': resolutionCost,
  };
}

class MainDashboard extends StatefulWidget {
  @override
  _MainDashboardState createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  AppData appData = AppData();
  bool _isLoading = false;
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  DateTime _selectedDate = DateTime(2026, 1, 30);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? dataString = prefs.getString('app_data');
      if (dataString != null) setState(() => appData = AppData.fromJson(jsonDecode(dataString)));
    } catch (e) { print('Error loading data: $e'); }
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_data', jsonEncode(appData.toJson()));
  }

  double get totalBalance => appData.transactions
      .where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount) -
      appData.transactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);

  double get totalIncome => appData.transactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
  double get totalExpense => appData.transactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);
  int get totalResolved => appData.complaints.where((c) => c.status == 'Resolved').length;
  int get totalPending => appData.complaints.where((c) => c.status == 'Pending').length;

  List<Transaction> get filteredTransactions {
    return appData.transactions
        .where((t) => _selectedDate.day == DateTime.parse(t.date).day && _selectedDate.month == DateTime.parse(t.date).month)
        .where((t) => _selectedCategory == 'All' || t.category == _selectedCategory)
        .toList().reversed.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('AMS Dashboard'),
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: _showDatePicker,
              child: Chip(
                label: Text('${_selectedDate.day}/${_selectedDate.month}', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: [
        RefreshIndicator(onRefresh: _loadData, child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: double.infinity, padding: EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)]), 
                borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]),
              child: Column(children: [
                Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: 8),
                Text('₹${totalBalance.toStringAsFixed(2)}', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              ]),
            ),
            SizedBox(height: 24),
            Row(children: [
              Expanded(child: _buildStatCard('Income', '₹${totalIncome.toStringAsFixed(2)}', Colors.green)),
              SizedBox(width: 12),
              Expanded(child: _buildStatCard('Expense', '₹${totalExpense.toStringAsFixed(2)}', Colors.red)),
            ]),
            SizedBox(height: 24),
            _buildTransactionsTable(),
          ]),
        )),
        _buildComplaintsTable(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF1E3A8A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Complaints'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _currentIndex == 0 ? () => _showAddTransactionDialog(context) : () => _showAddComplaintDialog(context),
        backgroundColor: Color(0xFF1E3A8A),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String label, String amount, Color color) => Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
    child: Column(children: [Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])), SizedBox(height: 8), Text(amount, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color))]),
  );

  Widget _buildTransactionsTable() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: DropdownButtonFormField<String>(value: _selectedCategory, decoration: InputDecoration(labelText: 'Filter by Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
        items: ['All', ...maintenanceCategories].map((c) => DropdownMenuItem(value: c, child: Text(c.length > 25 ? '${c.substring(0, 22)}...' : c))).toList(),
        onChanged: (v) => setState(() => _selectedCategory = v!),
      ),
    ),
    SizedBox(height: 16),
    Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(children: [
        Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
          child: Row(children: [Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))), Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))), Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))), Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 80)]),
        ),
        ...filteredTransactions.map((t) => _buildTransactionRowWithActions(t)),
        if (filteredTransactions.isEmpty) _buildEmptyState(Icons.receipt_long_outlined, 'No transactions found'),
      ]),
    ),
  ]);

  Widget _buildTransactionRowWithActions(Transaction t) => Container(margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4), child: Row(children: [
    Expanded(flex: 2, child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text(t.date, style: TextStyle(color: Colors.grey[600])))),
    Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t.title, style: TextStyle(fontWeight: FontWeight.w500)), Text(t.category.length > 20 ? '${t.category.substring(0, 17)}...' : t.category, style: TextStyle(fontSize: 12, color: Colors.grey[500]))])),
    Expanded(flex: 2, child: Text(t.category, style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)))),
    Expanded(flex: 2, child: Text('₹${t.amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: t.type == 'income' ? Colors.green[700] : Colors.red[700]))),
    Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: Icon(Icons.edit, size: 18, color: Colors.orange), onPressed: () => _showEditTransactionDialog(context, t)),
      IconButton(icon: Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _showDeleteTransactionDialog(context, t)),
    ]),
  ]));

  Widget _buildComplaintsTable() => RefreshIndicator(onRefresh: _loadData, child: SingleChildScrollView(
    physics: AlwaysScrollableScrollPhysics(),
    padding: EdgeInsets.all(16),
    child: Column(children: [
      Row(children: [Expanded(child: _buildComplaintStatCard('Resolved', totalResolved.toString(), Colors.green)), SizedBox(width: 12), Expanded(child: _buildComplaintStatCard('Pending', totalPending.toString(), Colors.orange))]),
      SizedBox(height: 24),
      Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(children: [
          Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
            child: Row(children: [Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))), Expanded(flex: 3, child: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))), Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))), Expanded(flex: 2, child: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold))), Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))), SizedBox(width: 60)]),
          ),
          ...appData.complaints.map((c) => _buildComplaintRow(c)),
          if (appData.complaints.isEmpty) _buildEmptyState(Icons.inbox_outlined, 'No complaints found'),
        ]),
      ),
    ]),
  ));

  Widget _buildComplaintStatCard(String label, String count, Color color) => Container(padding: EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Column(children: [Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])), SizedBox(height: 8), Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color))]));

  Widget _buildComplaintRow(Complaint c) => Container(margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4), child: Row(children: [
    Expanded(flex: 1, child: Text(c.id)),
    Expanded(flex: 3, child: Text(c.title)),
    Expanded(flex: 2, child: Container(padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8), decoration: BoxDecoration(color: c.status == 'Resolved' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(c.status, style: TextStyle(color: c.status == 'Resolved' ? Colors.green[700] : Colors.orange[700], fontWeight: FontWeight.w500)))),
    Expanded(flex: 2, child: Text(c.priority)),
    Expanded(flex: 2, child: Text(c.date)),
    SizedBox(width: 60, child: c.status == 'Pending' 
      ? IconButton(icon: Icon(Icons.check_circle, color: Colors.green), onPressed: () => _showResolveComplaintDialog(context, c))
      : IconButton(icon: Icon(Icons.visibility, color: Color(0xFF1E3A8A)), onPressed: () => _showComplaintDetails(context, c))),
  ]));

  Widget _buildEmptyState(IconData icon, String message) => Container(padding: EdgeInsets.all(40), child: Column(children: [Icon(icon, size: 64, color: Colors.grey[400]), SizedBox(height: 16), Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 16))]));

  void _showDatePicker() async {
    final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2025), lastDate: DateTime(2027));
    if (date != null) setState(() => _selectedDate = date);
  }

  void _showAddTransactionDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = maintenanceCategories.first;
    String selectedType = 'expense';
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text('Add Transaction'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleController, decoration: InputDecoration(labelText: 'Description')),
        TextField(controller: amountController, decoration: InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
        DropdownButtonFormField(value: selectedCategory, decoration: InputDecoration(labelText: 'Category'), items: maintenanceCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(), onChanged: (v) => setDialogState(() => selectedCategory = v!)),
        DropdownButtonFormField(value: selectedType, decoration: InputDecoration(labelText: 'Type'), items: ['income', 'expense'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(), onChanged: (v) => setDialogState(() => selectedType = v!)),
        Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: TextStyle(fontWeight: FontWeight.w500)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(onPressed: () {
          if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
            setState(() {
              final newId = 'TXN${(appData.transactions.length + 1).toString().padLeft(3, '0')}';
              appData.transactions.add(Transaction(id: newId, title: titleController.text, date: '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}', amount: double.tryParse(amountController.text) ?? 0.0, category: selectedCategory, type: selectedType));
            });
            _saveData();
            Navigator.pop(context);
          }
        }, child: Text('Add')),
      ],
    )));
  }

  void _showResolveComplaintDialog(BuildContext context, Complaint complaint) {
    final workSummaryController = TextEditingController();
    final costController = TextEditingController();
    String selectedExpenseType = 'Common';
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text('Resolution Details'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: workSummaryController, maxLines: 3, decoration: InputDecoration(labelText: 'Work Summary', hintText: 'What was the fix?')),
        DropdownButtonFormField(value: selectedExpenseType, decoration: InputDecoration(labelText: 'Expense Category'), items: expenseTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setDialogState(() => selectedExpenseType = v!)),
        TextField(controller: costController, decoration: InputDecoration(labelText: 'Total Cost (₹)'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(onPressed: () {
          final index = appData.complaints.indexWhere((c) => c.id == complaint.id);
          if (index != -1) {
            setState(() {
              appData.complaints[index] = Complaint(
                id: complaint.id, title: complaint.title, status: 'Resolved',
                priority: complaint.priority, date: complaint.date,
                assignedTo: complaint.assignedTo, workSummary: workSummaryController.text,
                expenseType: selectedExpenseType, resolutionCost: double.tryParse(costController.text) ?? 0.0,
              );
              // Auto-add expense if cost > 0
              if ((double.tryParse(costController.text) ?? 0.0) > 0) {
                final newId = 'TXN${(appData.transactions.length + 1).toString().padLeft(3, '0')}';
                appData.transactions.add(Transaction(id: newId, title: '${complaint.title} - Resolution', date: complaint.date, amount: double.tryParse(costController.text) ?? 0.0, category: selectedExpenseType, type: 'expense'));
              }
            });
            _saveData();
            Navigator.pop(context);
          }
        }, child: Text('Confirm Resolution')),
      ],
    )));
  }

  // Other dialog methods (add, edit, delete, complaint details) - same as before but shortened
  void _showAddComplaintDialog(BuildContext context) {
    final titleController = TextEditingController();
    final assignedController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(title: Text('Add Complaint'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
      TextField(controller: assignedController, decoration: InputDecoration(labelText: 'Assigned To')),
    ]), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      ElevatedButton(onPressed: () {
        if (titleController.text.isNotEmpty) {
          setState(() {
            final newId = 'CMP${(appData.complaints.length + 1).toString().padLeft(3, '0')}';
            appData.complaints.add(Complaint(id: newId, title: titleController.text, status: 'Pending', priority: 'Medium', date: '2026-01-30', assignedTo: assignedController.text.isEmpty ? 'Unassigned' : assignedController.text, workSummary: '', expenseType: 'Common', resolutionCost: 0.0));
          });
          _saveData();
          Navigator.pop(context);
        }
      }, child: Text('Add')),
    ]));
  }

  void _showComplaintDetails(BuildContext context, Complaint c) => showDialog(context: context, builder: (context) => AlertDialog(
    title: Text('${c.id} - ${c.title}'),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Status: ${c.status}'), Text('Priority: ${c.priority}'), Text('Assigned: ${c.assignedTo}'),
      Text('Work Summary: ${c.workSummary}'), Text('Expense Type: ${c.expenseType}'),
      Text('Resolution Cost: ₹${c.resolutionCost.toStringAsFixed(2)}'),
    ]),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
  ));

  void _showEditTransactionDialog(BuildContext context, Transaction t) {
    final titleController = TextEditingController(text: t.title);
    final amountController = TextEditingController(text: t.amount.toString());
    String selectedCategory = t.category;
    String selectedType = t.type;
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: Text('Edit Transaction'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleController, decoration: InputDecoration(labelText: 'Description')),
        TextField(controller: amountController, decoration: InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
        DropdownButtonFormField(value: selectedCategory, decoration: InputDecoration(labelText: 'Category'), items: maintenanceCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(), onChanged: (v) => setDialogState(() => selectedCategory = v!)),
        DropdownButtonFormField(value: selectedType, decoration: InputDecoration(labelText: 'Type'), items: ['income', 'expense'].map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase()))).toList(), onChanged: (v) => setDialogState(() => selectedType = v!)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(onPressed: () {
          final index = appData.transactions.indexWhere((tr) => tr.id == t.id);
          if (index != -1) {
            setState(() => appData.transactions[index] = Transaction(id: t.id, title: titleController.text, date: t.date, amount: double.tryParse(amountController.text) ?? 0.0, category: selectedCategory, type: selectedType));
            _saveData();
            Navigator.pop(context);
          }
        }, child: Text('Update')),
      ],
    )));
  }

  void _showDeleteTransactionDialog(BuildContext context, Transaction t) => showDialog(context: context, builder: (context) => AlertDialog(
    title: Text('Delete Transaction'),
    content: Text('Delete "${t.title}"?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () {
        setState(() => appData.transactions.removeWhere((tr) => tr.id == t.id));
        _saveData();
        Navigator.pop(context);
      }, child: Text('Delete', style: TextStyle(color: Colors.white))),
    ],
  ));
}

class ComplaintsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Complaints'), backgroundColor: Color(0xFF1E3A8A)), body: Center(child: Text('Use bottom tabs')));
}
