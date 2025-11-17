// hive_type_ids.dart
// This file centralizes all HiveType IDs to prevent conflicts.

// --- CORE ADAPTERS ---
const int kTimestampAdapterId = 0;
const int kDurationAdapterId = 1;
const int kSyncStatusTypeId = 2;

// --- MAIN MODELS ---
const int kUserModelTypeId = 10;
const int kQuestionTypeId = 11;
const int kSliderItemTypeId = 12;
const int kSubscriptionTypeId = 13;
const int kDailyTipTypeId = 14;
const int kTaskTypeId = 15;
const int kCourseTypeId = 16;
const int kDepartmentTypeId = 17;
const int kPointTransactionTypeId = 18;

// --- NOTIFICATION MODELS ---
const int kNotificationSettingsTypeId = 20;
const int kAppNotificationTypeId = 21;
const int kNotificationTypeAdapterId = 22;

// --- ENUMS ---
const int kQuestionFilterTypeId = 30;
const int kQuestionAccessTypeId = 31;
const int kQuestionStatusTypeId = 32;
const int kPriorityTypeId = 33;
const int kRecurrenceTypeId = 34;
const int kTaskStatusTypeId = 35;

// --- FIX: Added missing enum Type IDs for SliderModel ---
const int kSliderTypeTypeId = 36;
const int kSliderActionTypeTypeId = 37;
// --- END FIX ---

// --- CACHE MIXIN FIELDS ---
// These are field IDs used within models that use CacheMixin
// They start at 100 to avoid conflicts with model fields
const int kCacheMixinTypeId = 100; // Starting point for cache fields