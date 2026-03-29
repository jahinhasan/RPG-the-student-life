# Flutter Clean Architecture Layout

This project is now organized by feature, with role-based UI sections:

- admin screens are in features/admin/presentation/screens
- teacher screens are in features/teacher/presentation/screens
- student screens are in features/student/presentation/screens
- auth and entry screens are in features/auth/presentation/screens

## Folder Structure

lib/
	core/
	features/
		auth/
			data/
			domain/
			presentation/screens/
		admin/
			data/
			domain/
			presentation/screens/
		teacher/
			data/
			domain/
			presentation/screens/
		student/
			data/
			domain/
			presentation/screens/

## Clean Architecture Rules

1. presentation: widgets, screens, and state adapters only.
2. domain: entities, use-cases, and abstract repositories.
3. data: repository implementations, models, and data sources.
4. core: shared utilities, constants, base errors, and cross-feature abstractions.

## Migration Notes

- Existing route and app entry imports were updated to the new feature locations.
- Existing services currently remain in lib/services for compatibility.
- Next step is to move each service into the corresponding feature/data layer behind domain repository interfaces.
