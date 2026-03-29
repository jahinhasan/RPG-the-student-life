# Admin/Teacher/Batch System Implementation Guide

## Overview
This document outlines the complete roadmap for implementing the teacher-assigned mission system with admin management, student class grouping, and performance tracking.

**Timeline:** Phase 1 (Data Setup) → Phase 2 (Teacher System) → Phase 3 (Student Features) → Phase 4 (Admin Dashboard)

---

## Current State (Completed)

✅ **Services Created:**
- `admin_service.dart` - Full CRUD for batches, levels, terms, classes, teachers, students
- Complete Firestore schema design and security rules

✅ **UI Scaffolding:**
- `admin_panel_screen.dart` - Admin dashboard with 5 tabs (Hierarchy, Teachers, Classes, Students, Analytics)
- `teacher_mission_screen.dart` - Teacher interface for viewing classes and creating scoped missions
- Routes registered: `/admin` and `/teacher-missions`

✅ **Firestore Schema:**
- Documented structure for all collections (batches, levels, terms, classes, users, missions, attendance, marks)
- Example queries and security rules
- Indexes required for efficient data retrieval

---

## Phase 1: Data Initialization (Admin Setup)

### Goal
Set up the organizational hierarchy: batches, levels, terms, classes

### What Admin Does
1. Navigate to `/admin` → "Hierarchy" tab
2. Create Batches (e.g., 2023, 2024)
3. Create Levels (1, 2, 3, 4 for 4-year degree)
4. Create Terms (Spring, Fall, Summer)
5. Create Classes (combinations of batch+level+term+section)

### Required Admin Function
```dart
// In admin_panel_screen.dart - _HierarchyTab
Dialog for creating:
- Batch with year
- Level with number
- Term with name and number
- Class with batch+level+term+section+teacher assignment
```

### Implementation Checklist

- [ ] Click "Add Batch" → Enter year 2023 → Batch created
- [ ] Click "Add Level" → Enter 1 → Level 1 created
- [ ] Click "Add Term" → Enter Spring, 1 → Spring created
- [ ] Verify batches/levels/terms appear in lists
- [ ] Create minimum 2 classes (e.g., Batch 2023, Level 1, Term 1, Section A & B)

### Database Check
```javascript
// Firestore Console
db.collection('batches').get() // Should have 2023, 2024
db.collection('levels').get() // Should have 1, 2, 3, 4
db.collection('terms').get() // Should have Spring, Fall, Summer
db.collection('classes').get() // Should have classes with assignedTeacherIds = []
```

---

## Phase 2: Teacher Assignment & Mission Creation

### Goal
Assign teachers to classes and enable them to create scoped missions

### What Admin Does
1. Navigate to `/admin` → "Teachers" tab
2. View all teachers from "All Teachers" section
3. Click teacher → "Assign Classes"
4. Select classes to assign → Save

### Teacher Experience (New)
1. Login as teacher
2. Navigate to `/teacher-missions`
3. "My Classes" tab shows assigned classes with student rosters
4. "Create Mission" tab allows defining missions for each class

### Required Implementation

**AdminService Already Has:**
```dart
assignTeachersToClass({
  required String classId,
  required List<String> teacherIds,
})

createTeacherMission({
  required String teacherId,
  required String classId,
  required String title,
  required String description,
  ...
})
```

**TODO: Update Admin Panel Class Assignment Dialog**

In `admin_panel_screen.dart`, update `TeacherTile.onTap("Assign Classes")`:

```dart
void _showAssignClassesDialog(BuildContext context, String teacherId) {
  // TODO: 
  // 1. Fetch all available classes from Firestore
  // 2. Show multi-select checkbox list
  // 3. Save selected classes to teacher's assignedClassIds
  // 4. Update class's assignedTeacherIds
}
```

### Implementation Checklist

- [ ] Admin assigns Dr. Rahman to Class A (Batch 2023, Level 1, Term 1, Section A)
- [ ] Admin assigns Dr. Ahmed to Class A (same class, multiple teachers)
- [ ] Dr. Rahman logs in, navigates to `/teacher-missions`
- [ ] Dr. Rahman sees "My Classes" with Section A displayed
- [ ] Dr. Rahman clicks "Class Roster" → Sees enrolled students
- [ ] Dr. Rahman creates mission:
  - Title: "Linear Equations Problem Set"
  - Description: "Solve problems from Chapter 2"
  - Type: "assignment"
  - XP: 100
  - Due Date: Next Friday
  - Instructions: "Submit PDF format"
- [ ] Mission appears in Firestore at `/missions/{missionId}` with `teacherId` and `classId`

### Database Check
```javascript
// Teacher document
db.collection('users').doc(teacherId).get()
// Should have: { role: 'teacher', assignedClassIds: ['class_...', ...] }

// Class document
db.collection('classes').doc(classId).get()
// Should have: { assignedTeacherIds: ['teacher_001', 'teacher_002'] }

// Mission document
db.collection('missions').doc(missionId).get()
// Should have: { teacherId: 'teacher_001', classId: 'class_...' }
```

---

## Phase 3: Student Features & Class Filtering

### Goal
Students see missions only from their assigned teachers/classes

### What Student Does
1. Login as student in a class
2. Navigate to `/missions` or home daily missions
3. Only see missions from teachers assigned to their classes
4. See teacher name, course code, class scope info
5. Complete mission → XP awarded to their profile

### Required Changes

**1. Update `mission_service.dart`**

Currently, `streamMissions()` returns global + completed missions. Refactor to accept `classIds` parameter:

```dart
Stream<List<Map<String, dynamic>>> streamMissions({
  required List<String> classIds,  // Student's enrolled class IDs
}) {
  // Changed: Fetch missions where classId in classIds OR type == global
  // Returns: Teacher-scoped + global missions
}
```

**2. Update `student_home_screen.dart`**

```dart
Future<void> build(BuildContext context, WidgetRef ref) {
  // Get current user's classIds
  final userClassIds = await ref.read(authServiceProvider)
    .getCurrentUserClassIds();
  
  // Watch missions scoped to their classes
  final missions = ref.watch(missionsProvider(classIds: userClassIds));
  
  // Already filters by daily + claim status
  // New filter: Only show missions from assigned teachers/classes
}
```

**3. Update `missions_screen.dart`**

Same class-scoped filtering as home screen

### Implementation Checklist

- [ ] Student enrolled in Class A (Batch 2023, Level 1, Term 1, Section A)
- [ ] Student's `classIds` = ['class_2023_level1_term1_A']
- [ ] Dr. Rahman creates mission scoped to Class A
- [ ] Student sees mission on `/missions` tab
- [ ] Mission card shows:
  - Title
  - Teacher: "Dr. Rahman"
  - Course: "MATH-211 • Calculus I"
  - Batch: "2023 • Level 1 • Term 1 • Section A"
  - XP: 100
  - Due Date: Next Friday
- [ ] Student taps mission → bottom sheet shows instructions
- [ ] Student claims mission → XP added + mission disappears

### Database Setup
```javascript
// Student document - Add classIds
db.collection('users').doc(studentId).update({
  batchId: 'batch_2023',
  levelId: 'level_1',
  termId: 'term_1',
  sectionName: 'A',
  classIds: ['class_2023_level1_term1_A'],
})
```

---

## Phase 4: Performance Tracking & Admin Analytics

### Goal
Track student attendance, marks, and performance per class

### What Teacher Does
1. Navigate to `/teacher-missions` → "My Classes"
2. (Future) Click class → "View Analytics"
3. See class roster with:
   - Attendance %
   - Average marks
   - Mission completion %
4. Record attendance during class
5. Record marks for assignments/exams

### What Admin Does
1. Navigate to `/admin` → "Analytics" tab
2. View system-wide metrics:
   - Total students, teachers, classes
   - Average attendance across system
   - Mission completion rates
   - Top performing classes

### Required Implementation

**AdminService Already Has:**
```dart
recordAttendance({
  required String studentId,
  required String classId,
  required DateTime date,
  required bool isPresent,
})

recordMarks({
  required String studentId,
  required String classId,
  required String assessmentName,
  required double marksObtained,
  required double totalMarks,
})
```

**TODO: Create Teacher Analytics Screen**

New file: `teacher_analytics_screen.dart`

```dart
class TeacherAnalyticsScreen extends ConsumerWidget {
  final String classId;
  
  build() {
    // Tab 1: Attendance - List each student's attendance % + mark button
    // Tab 2: Marks - Show marks by assessment + add new assessment
    // Tab 3: Performance - Charts showing mission completion, avg marks, etc.
  }
}
```

**TODO: Update Admin Analytics Tab**

In `admin_panel_screen.dart`, populate `_AnalyticsTab`:

```dart
class _AnalyticsTab extends ConsumerWidget {
  build() {
    // Fetch stats from Firestore:
    // - Total teachers: users where role == 'teacher'
    // - Total students: users where role == 'student'
    // - Total classes: classes collection
    // - Avg attendance: Calculate from attendance subcollections
    // - Missions completed: Count completedMissions across all students
  }
}
```

### Implementation Checklist

- [ ] Teacher records attendance for Class A lecture (20 students present, 2 absent)
- [ ] Teacher records marks for "Midterm Exam" (MATH-211):
  - Student 1: 85/100
  - Student 2: 92/100
  - etc.
- [ ] Teacher navigates to class analytics → Sees attendance % and assessment scores
- [ ] Admin views system analytics → Sees:
  - 2 classes
  - 42 total students
  - 5 teachers
  - 95% avg attendance
  - 38 missions completed this semester

### Database Check
```javascript
// Attendance subcollection
db.collection('users').doc(studentId)
  .collection('attendance').doc(classId).get()
// Should have: { records: [{ date, isPresent }, ...] }

// Marks subcollection
db.collection('users').doc(studentId)
  .collection('marks').doc(classId).get()
// Should have: { midterm: { obtained, total, percentage }, ... }
```

---

## Phase 5: Refinements & Production

### Additional Features to Add

**1. Mission Editing & Deletion**
```dart
// In teacher_mission_screen.dart
- Add "Edit Mission" option for unpublished missions
- Add "Delete Mission" with confirmation dialog
- Prevent editing missions with student submissions
```

**2. Student Performance Dashboard**
```dart
// New route: `/student-performance`
- Show all enrolled classes
- Per-class stats (attendance, marks, missions)
- Comparison with class average
```

**3. Notification System**
```dart
// When teacher creates mission:
- Send notification to all students in class
// When teacher records attendance:
- Student can see if they were marked absent
// When teacher adds feedback:
- Student sees feedback on completed mission
```

**4. Role-Based Navigation**
```dart
// In splash_screen.dart - Update role check
if (role == 'admin') {
  navigate to '/admin'
} else if (role == 'teacher') {
  navigate to '/teacher-missions'
} else if (role == 'student') {
  navigate to '/studentHome'
}
```

**5. Teacher Self-Promotion Flow**
```dart
// Teachers can request admin promotion
// Admin approves promotion in admin panel
// System updates role from 'teacher' to 'admin'
```

---

## Implementation Priority & Dependencies

### Must Do (Block Student Missions)
1. ✅ Admin Service - DONE
2. ✅ Admin Panel UI - DONE
3. ✅ Teacher Mission Screen - DONE
4. ⏳ **Phase 1: Create batches, levels, terms, classes (Admin)**
5. ⏳ **Phase 2: Assign teachers to classes (Admin)**
6. ⏳ **Phase 3: Update student data with classIds**
7. ⏳ **Phase 4: Update mission_service.dart to support class-scoped filtering**
8. ⏳ **Phase 5: Update student screens to filter by classIds**

### Should Do (Nice to Have)
9. ⏳ **Phase 4: Teacher analytics screen**
10. ⏳ **Phase 5: Admin system analytics**
11. ⏳ **Phase 5: Student performance dashboard**
12. ⏳ **Phase 5: Notification system**

### Can Do Later (Polish)
13. ⏳ Mission editing/deletion
14. ⏳ Attendance marking UI
15. ⏳ Marks entry UI
16. ⏳ Role-based home screen routing

---

## Command Reference

### Test Data Generation (Firestore)
```javascript
// Create test batch
db.collection('batches').doc('batch_2023').set({
  year: 2023,
  createdAt: new Date()
})

// Create test level
db.collection('levels').doc('level_1').set({
  levelNumber: 1,
  createdAt: new Date()
})

// Create test term
db.collection('terms').doc('term_1').set({
  termName: 'Spring',
  termNumber: 1,
  createdAt: new Date()
})

// Create test class
db.collection('classes').doc('class_2023_level1_term1_A').set({
  batchId: 'batch_2023',
  levelId: 'level_1',
  termId: 'term_1',
  sectionName: 'A',
  assignedTeacherIds: [],
  createdAt: new Date()
})

// Update student with class enrollment
db.collection('users').doc(studentId).update({
  batchId: 'batch_2023',
  levelId: 'level_1',
  termId: 'term_1',
  sectionName: 'A',
  classIds: ['class_2023_level1_term1_A']
})

// Update teacher with class assignment
db.collection('users').doc(teacherId).update({
  assignedClassIds: ['class_2023_level1_term1_A']
})

// Update class with teacher assignment
db.collection('classes').doc('class_2023_level1_term1_A').update({
  assignedTeacherIds: ['teacher_001']
})
```

### Flutter Hot Reload
```bash
# After making changes, restart app
flutter run -d 10EDAB03RR00087

# Or navigate directly in app:
# 1. Admin: tap admin panel tile (once added to home/menu)
# 2. Teacher: tap "Mission Management" (add to dashboard)
# 3. Student: missions already visible at /missions
```

---

## Testing Checklist

### Admin Flow
- [ ] Create 2 batches (2023, 2024)
- [ ] Create 4 levels (1, 2, 3, 4)
- [ ] Create 3 terms (Spring, Fall, Summer)
- [ ] Create 4 classes (different combinations)
- [ ] Verify all appear in respective tabs

### Teacher Flow
- [ ] Assign Dr. Rahman to 2 classes
- [ ] Assign Dr. Ahmed to 1 class
- [ ] Dr. Rahman logs in → sees 2 classes in "My Classes"
- [ ] Dr. Rahman creates 3 missions (daily, weekly, assignment)
- [ ] Dr. Ahmed creates 1 mission
- [ ] Verify missions appear in Firestore with correct teacherId/classId

### Student Flow
- [ ] Enroll Student 1 in Class A with Dr. Rahman
- [ ] Enroll Student 2 in Class A with Dr. Rahman
- [ ] Enroll Student 3 in Class B with Dr. Ahmed
- [ ] Student 1 sees only Dr. Rahman's missions
- [ ] Student 2 sees only Dr. Rahman's missions
- [ ] Student 3 sees only Dr. Ahmed's missions
- [ ] All students see mission details (teacher, course, class scope)

### Verification
- [ ] No console errors during admin operations
- [ ] Firestore data matches UI displays
- [ ] Real-time updates work (create mission, refresh student app)
- [ ] XP awards work after class-scoped missions

---

## Next Steps

1. **Immediate:** Begin Phase 1 - Set up test batches/levels/terms/classes via admin panel
2. **Short-term:** Complete Phase 2 - Assign teachers and test mission creation
3. **Medium-term:** Complete Phase 3 - Update student mission filtering and test end-to-end flow
4. **Long-term:** Complete Phase 4 & 5 - Add analytics and performance tracking

**Expected Timeline:**
- Phase 1-2: 1-2 hours (mostly clicking in UI)
- Phase 3: 2-3 hours (code changes to mission_service.dart and student screens)
- Phase 4: 2-3 hours (analytics UI + queries)
- Phase 5: 1-2 hours (refinements)

**Total: ~8-11 hours to full production readiness**
