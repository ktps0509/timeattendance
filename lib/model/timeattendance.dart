class TimeAttendance {
  int _employee_id;
  DateTime _checkIn;
  String _name;
  DateTime _checkOut;

  TimeAttendance(this._employee_id,this._checkIn, this._name,this._checkOut);

  factory TimeAttendance.fromJson(Map<String, dynamic> json) {
    int employee_id = json['employee_id'];
    DateTime checkIn = DateTime.parse(json['checkIn']);
    String name = json['name'];
    DateTime checkOut = DateTime.parse(json['checkOut']);
    return TimeAttendance(employee_id,checkIn, name, checkOut);
  }

  Map<String, dynamic> toJson() => {
    'employee_id': this._employee_id.toString(),
    'checkIn': this._checkIn.toIso8601String(),
    'name': this._name,
    'checkOut': this._checkOut.toIso8601String(),
  };

  String getName() {
    return this._name;
  }

  DateTime getTimeIn() {
    return this._checkIn;
  }
}