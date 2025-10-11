import '../models/course_model.dart';
import '../models/department_model.dart';
import 'courses.dart';

final List<Department> allDepartments = [
  // Faculty of Science & Information Technology
  Department(id: "cse", name: "Computer Science and Engineering"),
  Department(id: "swe", name: "Software Engineering"),
  Department(id: "mct", name: "Multimedia and Creative Technology"),
  Department(id: "cis", name: "Computing and Information System"),
  Department(id: "itm", name: "Information Technology and Management"),
  Department(id: "esdm", name: "Environmental Science and Disaster Management"),
  Department(id: "pess", name: "Physical Education and Sports Science"),

  // Faculty of Engineering
  Department(id: "ice", name: "Information and Communication Engineering"),
  Department(id: "te", name: "Textile Engineering"),
  Department(id: "eee", name: "Electrical and Electronic Engineering"),
  Department(id: "civil", name: "Civil Engineering"),
  Department(id: "arch", name: "Architecture"),

  // Faculty of Allied Health Sciences
  Department(id: "nfe", name: "Nutrition and Food Engineering"),
  Department(id: "pharma", name: "Pharmacy"),

  // Faculty of Business & Entrepreneurship
  Department(id: "bba", name: "Business Administration"),
  Department(id: "thm", name: "Tourism and Hospitality Management"),
  Department(id: "ent", name: "Entrepreneurship"),
  Department(id: "re", name: "Real Estate"),
  Department(id: "management", name: "Management"),
  Department(id: "accounting", name: "Accounting"),
  Department(id: "finance", name: "Finance and Banking"),
  Department(id: "marketing", name: "Marketing"),
  Department(id: "ebm", name: "Business Studies in E-Business Management"),
  Department(id: "com", name: "Commerce"),

  // Faculty of Health & Life Sciences
  Department(id: "geb", name: "Genetic Engineering and Biotechnology"),
  Department(id: "agriculture", name: "Agricultural Science"),

  // Faculty of Humanities & Social Sciences
  Department(id: "jmc", name: "Journalism Media and Communication"),
  Department(id: "law", name: "Law"),
  Department(id: "english", name: "English"),
];

Map<String, List<Course>> departmentCourseMap = {
  "cse": cseCourseList,
  "swe": sweCourseList,
  "mct": mctCourseList,
  "esdm": esdmCourseList,
  "cis": cisCourseList,
  "itm": itmCourseList,
  "pess": pessCourseList,
  "bba": bbaCourseList,
  "ebm": bsCourseList,
  "re": reCourseList,
  "thm": thmCourseList,
  "ent": eCourseList,
  "english": englishCourseList,
  "law": lawCourseList,
  "jmc": jmcCourseList,
  "ice": iceCourseList,
  "te": teCourseList,
  "eee": eeeCourseList,
  "arch": archCourseList,
  "pharma": pharmacyCourseList,
  "nfe": nfeCourseList,
  "ph": phCourseList,
  "management": bbaManagementCourseList,
  "accounting": bbaAccountCourseList,
  "finance": bbaFiBankCourseList,
  "marketing": bbaMarketingCourseList,
  "geb": gebCourseList,
  "agriculture": agricultureCourseList
};

List<Course> getCourseList(String departmentId) {
  return departmentCourseMap[departmentId] ?? [];
}

String getDepartmentNameById(String? id) {
  if (id == null) return 'Unknown Department'; // Handle null case

  try {
    Department department = allDepartments.firstWhere(
          (dept) => dept.id == id,
      orElse: () => Department(id: '', name: 'Unknown Department'),
    );
    return department.name;
  } catch (e) {
    return 'Unknown Department'; // Fallback in case of unexpected errors
  }
}