# Firestore Database Schema - Teacher-Assigned Mission System

## Overview
This schema supports a university-scale gamified learning platform where:
- **Students** are organized by **Batch** (admission year), **Level** (academic level), **Term** (semester), and **Section** (A/B/C)
- **Teachers** assign **Missions** to specific **Classes** (batch + level + term + section combination)
- **Admins** manage the organizational structure and teacher-class assignments
- **Performance** (marks, attendance) is tracked per student per class

---

## Collection Structure

### `/admins/{adminId}`
Stores admin user accounts and metadata.

```json
{
  "name": "Dr. John Doe",
  "email": "admin@university.edu",
  "universityId": "ADMIN_001",
  "role": "admin",
  "createdAt": "Timestamp",
  "lastLogin": "Timestamp"
}
```

**Fields:**
- `name` (string): Admin's full name
- `email` (string): Admin's email address
- `universityId` (string): Unique ID within university system
- `role` (string): Always "admin"
- `createdAt` (timestamp): Account creation time
- `lastLogin` (timestamp): Last login time

---

### `/batches/{batchId}`
Represents university admission cohorts (e.g., 2023, 2024).

```json
{
  "year": 2023,
  "createdAt": "Timestamp"
}
```

**Fields:**
- `year` (number): Admission year
- `createdAt` (timestamp): When batch was created

**Example IDs:** `batch_2023`, `batch_2024`

---

### `/levels/{levelId}`
Represents academic levels or years (e.g., Year 1, Year 2, Year 3, Year 4).

```json
{
  "levelNumber": 1,
  "levelName": "First Year",
  "createdAt": "Timestamp"
}
```

**Fields:**
- `levelNumber` (number): Level order (1, 2, 3, 4, etc.)
- `levelName` (string, optional): Human-readable name
- `createdAt` (timestamp): When level was created

**Example IDs:** `level_1`, `level_2`, `level_3`, `level_4`

---

### `/terms/{termId}`
Represents academic terms or semesters (e.g., Spring, Fall, Summer).

```json
{
  "termName": "Spring",
  "termNumber": 1,
  "createdAt": "Timestamp"
}
```

**Fields:**
- `termName` (string): Term name (Spring, Fall, Summer, etc.)
- `termNumber` (number): Term order within an academic year
- `createdAt` (timestamp): When term was created

**Example IDs:** `term_1`, `term_2`, `term_3`

---

### `/classes/{classId}`
Represents a unique class combining batch, level, term, and section. Each class can have multiple teachers.

```json
{
  "batchId": "batch_2023",
  "levelId": "level_1",
  "termId": "term_1",
  "sectionName": "A",
  "assignedTeacherIds": [
    "teacher_001",
    "teacher_002"
  ],
  "createdAt": "Timestamp"
}
```

**Fields:**
- `batchId` (string): Reference to batch this class belongs to
- `levelId` (string): Reference to level
- `termId` (string): Reference to term
- `sectionName` (string): Section identifier (A, B, C, etc.)
- `assignedTeacherIds` (array): List of teacher IDs assigned to this class
- `createdAt` (timestamp): When class was created

**Example ID:** `class_2023_level1_term1_A`

**Unique Key:** Combination of batchId + levelId + termId + sectionName

---

### `/users/{userId}`
Central user collection for all authenticated users (students, teachers, admins).

#### Student Record
```json
{
  "email": "student@university.edu",
  "name": "Ahmed Hassan",
  "role": "student",
  "xp": 4500,
  "level": 12,
  "xpToNextLevel": 3200,
  "avatar": {
    "skinColor": "#FF6B6B",
    "clothColor": "#4ECDC4",
    "hat": "crown",
    "pet": "dragon"
  },
  "batchId": "batch_2023",
  "levelId": "level_1",
  "termId": "term_1",
  "sectionName": "A",
  "classIds": [
    "class_2023_level1_term1_A",
    "class_2023_level1_term1_B"  // Student can be in multiple electives
  ],
  "createdAt": "Timestamp",
  "lastActive": "Timestamp"
}
```

#### Teacher Record
```json
{
  "email": "teacher@university.edu",
  "name": "Dr. Rahman",
  "role": "teacher",
  "universityId": "TEACH_001",
  "department": "Computer Science",
  "assignedClassIds": [
    "class_2023_level1_term1_A",
    "class_2023_level2_term1_A"
  ],
  "createdAt": "Timestamp",
  "lastActive": "Timestamp"
}
```

#### Admin Record
```json
{
  "email": "admin@university.edu",
  "name": "Dr. John Doe",
  "role": "admin",
  "universityId": "ADMIN_001",
  "createdAt": "Timestamp",
  "lastActive": "Timestamp"
}
```

**Common Fields:**
- `email` (string): User's email address
- `name` (string): User's full name
- `role` (string): "student", "teacher", or "admin"
- `createdAt` (timestamp): Account creation time
- `lastActive` (timestamp): Last activity time

**Student-specific:**
- `xp` (number): Experience points
- `level` (number): Gamification level
- `xpToNextLevel` (number): XP remaining for next level
- `avatar` (object): Customization data
- `batchId`, `levelId`, `termId`, `sectionName`: Class membership
- `classIds` (array): All classes student is enrolled in

**Teacher-specific:**
- `universityId` (string): Official university ID
- `department` (string): Department/Faculty name
- `assignedClassIds` (array): Classes taught

---

### `/missions/{missionId}`
Global and teacher-assigned missions. Supports both legacy global missions and new teacher-scoped assignments.

#### Teacher-Assigned Mission (Primary)
```json
{
  "title": "Linear Equations Problem Set",
  "desc": "Solve 10 linear equation problems from chapter 2",
  "type": "daily",
  "xp": 100,
  "progress": 0,
  "dueDate": "Timestamp",
  "instructions": "Complete by Friday midnight. Submit solutions in PDF format.",
  "teacherId": "teacher_001",
  "classId": "class_2023_level1_term1_A",
  "courseName": "Calculus I",
  "courseCode": "MATH-211",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

#### Global Mission (Legacy)
```json
{
  "title": "Daily Bonus: Help 3 Classmates",
  "desc": "Assist three classmates with their studies",
  "type": "daily",
  "xp": 50,
  "progress": 0,
  "createdAt": "Timestamp"
}
```

**Fields:**
- `title` (string): Mission name
- `desc` (string): Short description
- `type` (string): "daily", "weekly", "achievement", "assignment"
- `xp` (number): XP reward for completion
- `progress` (number): Completion percentage (0-100)
- `dueDate` (timestamp): When mission is due (for assignments)
- `instructions` (string): Detailed instructions
- `teacherId` (string, optional): Teacher who created it
- `classId` (string, optional): Target class
- `courseName` (string, optional): Associated course
- `courseCode` (string, optional): Course code (MATH-211, CS-101, etc.)
- `createdAt` (timestamp): Creation time
- `updatedAt` (timestamp): Last modification time

**Indexing:** For quick queries:
- Query teacher missions: `missions` where `teacherId == X`
- Query class missions: `missions` where `classId == X`
- Query by type: `missions` where `type == 'daily'`

---

### `/users/{userId}/completedMissions/{missionId}`
Records when a student has completed a mission.

```json
{
  "missionId": "mission_001",
  "title": "Linear Equations Problem Set",
  "completedAt": "Timestamp",
  "xpAwarded": 100,
  "teacherFeedback": "Great work! Check comment 5.",
  "rating": 4.5
}
```

**Fields:**
- `missionId` (string): Reference to mission
- `title` (string): Mission title at completion time
- `completedAt` (timestamp): When completed
- `xpAwarded` (number): XP points given
- `teacherFeedback` (string, optional): Teacher's feedback
- `rating` (number, optional): Teacher's rating (0-5)

---

### `/users/{userId}/attendance/{classId}`
Tracks attendance records for each student in each class.

```json
{
  "classId": "class_2023_level1_term1_A",
  "records": [
    {
      "date": "Timestamp",
      "isPresent": true
    },
    {
      "date": "Timestamp",
      "isPresent": false
    }
  ]
}
```

**Fields:**
- `classId` (string): Class reference
- `records` (array of objects): Daily attendance records
  - `date` (timestamp): Date of class
  - `isPresent` (boolean): Whether student was present

---

### `/users/{userId}/marks/{classId}`
Stores student marks and assessments for each class.

```json
{
  "classId": "class_2023_level1_term1_A",
  "midterm": {
    "obtained": 75,
    "total": 100,
    "percentage": "75.00",
    "recordedAt": "Timestamp"
  },
  "final": {
    "obtained": 82,
    "total": 100,
    "percentage": "82.00",
    "recordedAt": "Timestamp"
  },
  "assignment_1": {
    "obtained": 18,
    "total": 20,
    "percentage": "90.00",
    "recordedAt": "Timestamp"
  }
}
```

**Fields:**
- `classId` (string): Class reference
- Assessment records (key = assessment name):
  - `obtained` (number): Marks obtained
  - `total` (number): Total possible marks
  - `percentage` (string): Calculated percentage
  - `recordedAt` (timestamp): When marks were recorded

---

## Access Patterns & Common Queries

### Student's Current Classes
```
Query: /classes where batchId == student.batchId 
       AND levelId == student.levelId 
       AND termId == student.termId
Result: All classes student can take (different sections)
```

### Student's Available Missions
```
Query: /missions where classId in student.classIds
       AND (type == 'daily' OR dueDate >= currentDate)
Filter client-side to exclude already completed missions
```

### Teacher's Classes
```
Query: /classes where assignedTeacherIds contains teacher.id
Result: All classes taught by this teacher
```

### Class Roster
```
Query: /users where classIds contains classId
       AND role == 'student'
Result: All students in specific class
```

### Student Performance Report
```
Fetch: /users/{studentId}/completedMissions
Fetch: /users/{studentId}/marks/{classId}
Fetch: /users/{studentId}/attendance/{classId}
Combine: Calculate totals and averages
```

---

## Data Integrity Rules

1. **Class Uniqueness:** Only one class per (batch, level, term, section) combination
2. **Teacher Assignment:** Teachers can be assigned to multiple classes
3. **Student Enrollment:** Students can be in multiple classes (e.g., electives)
4. **Mission Scope:** Teacher-assigned missions must have teacherId AND classId
5. **Completion Records:** One completedMission entry per student per mission (idempotent)
6. **Marks Recording:** Overwriting assessment marks updates the record (idempotent)

---

## Migration Path (From Global Missions)

### Phase 1: Data Structure Setup
1. Create `/batches`, `/levels`, `/terms` collections
2. Migrate existing students' batch/level/term/section to new schema
3. Create `/classes` with empty `assignedTeacherIds`

### Phase 2: Teacher Assignment
4. Create teacher `.assignedClassIds` arrays
5. Query existing teacher permissions and map to classes
6. Populate class `.assignedTeacherIds` based on mappings

### Phase 3: Mission Transition
7. Keep global missions as-is (unassigned)
8. Teachers create new missions scoped to their classes
9. Gradually phase out global missions (or mark as "University-Wide")

### Phase 4: Performance Tracking
10. Create `/attendance` and `/marks` subcollections
11. Teachers start recording attendance and marks

---

## Indexes Required

### Firestore Composite Indexes

1. **Classes by Level+Term+Batch:**
   - Collection: `classes`
   - Fields: `batchId` (Ascending), `levelId` (Ascending), `termId` (Ascending)

2. **Missions by Class:**
   - Collection: `missions`
   - Fields: `classId` (Ascending), `type` (Ascending)

3. **Missions by Teacher:**
   - Collection: `missions`
   - Fields: `teacherId` (Ascending), `classId` (Ascending)

4. **Users by Role:**
   - Collection: `users`
   - Fields: `role` (Ascending), `createdAt` (Descending)

5. **Students by Class:**
   - Collection: `users`
   - Fields: `classIds` (Contains Array), `role` (Ascending)

---

## Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Admins can access everything
    match /{document=**} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "admin";
    }
    
    // Teachers can read their classes and students
    match /classes/{classId} {
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.assignedTeacherIds;
    }
    
    // Teachers can read students in their classes
    match /users/{studentId} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "teacher" &&
        get(/databases/$(database)/documents/users/$(studentId)).data.classIds intersects
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.assignedClassIds;
    }
    
    // Students can read own profile and their missions
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

---

## Example Data Population

### Creating a Class Structure
1. Create Batch 2023
2. Create Level 1, Level 2, Level 3
3. Create Terms: 1 (Spring), 2 (Fall), 3 (Summer)
4. Create Class: Batch 2023 + Level 1 + Term 1 + Section A
5. Assign Teachers: Dr. Rahman, Dr. Ahmed
6. Enroll Students: 30 students in this class
7. Teachers create missions scoped to this class

### Recording Student Performance
1. Teacher creates mission "Assignment 1: Linear Equations"
2. Student completes and submits
3. Mission added to `/users/{studentId}/completedMissions`
4. Teacher records marks in `/users/{studentId}/marks/{classId}`
5. System calculates and displays performance dashboard

---

## Performance Considerations

- **Batch Operations:** Use batch writes for bulk class/student assignments
- **Real-time Updates:** Use StreamProvider for active class lists
- **Caching:** Cache batch/level/term lists (rarely change)
- **Pagination:** Implement pagination for large student rosters
- **Subcollections:** Keep completedMissions and marks as subcollections to avoid bloating user documents
