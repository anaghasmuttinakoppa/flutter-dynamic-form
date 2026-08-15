/// Supported form field types.
enum FieldType {
  /// Single-line free text.
  text,

  /// Email address input with email keyboard and validation.
  email,

  /// Obscured password input.
  password,

  /// Numeric input.
  number,

  /// Phone number input with phone keyboard.
  phone,

  /// Multi-line text area.
  multiline,

  /// Boolean checkbox.
  checkbox,

  /// Boolean switch.
  switchField,

  /// Single-select radio group.
  radio,

  /// Single-select dropdown.
  dropdown,

  /// Multi-select filter chips.
  chips,

  /// Date picker.
  date,

  /// Time picker.
  time,

  /// Combined date + time picker.
  dateTime,

  /// Nested field group.
  group,

  /// Repeatable list of nested field groups (Phase 5).
  repeatable,

  /// Image gallery picker (Phase 4).
  image,

  /// Generic file picker (Phase 4).
  file,

  /// Camera capture (Phase 4).
  camera,

  /// Geolocation (Phase 4).
  location,

  /// Numeric slider.
  slider,

  /// Range slider.
  rangeSlider,

  /// Star / numeric rating.
  rating,

  /// Freehand signature pad.
  signature,

  /// Color picker.
  color,

  /// Custom plugin-rendered type (resolved by string in [extra]/typeName]).
  custom,

  /// Unknown / unsupported type (rendered as a placeholder).
  unknown;

  /// Parses a string into a [FieldType], defaulting to [unknown].
  static FieldType fromString(String? value) {
    if (value == null || value.isEmpty) return FieldType.unknown;
    switch (value.toLowerCase().trim()) {
      case 'text':
      case 'string':
        return FieldType.text;
      case 'email':
        return FieldType.email;
      case 'password':
        return FieldType.password;
      case 'number':
      case 'int':
      case 'integer':
      case 'double':
      case 'numeric':
        return FieldType.number;
      case 'phone':
      case 'tel':
      case 'telephone':
        return FieldType.phone;
      case 'multiline':
      case 'textarea':
      case 'text_area':
        return FieldType.multiline;
      case 'checkbox':
      case 'check':
      case 'bool':
      case 'boolean':
        return FieldType.checkbox;
      case 'switch':
      case 'toggle':
        return FieldType.switchField;
      case 'radio':
      case 'radiogroup':
      case 'radio_group':
        return FieldType.radio;
      case 'dropdown':
      case 'select':
      case 'selectbox':
        return FieldType.dropdown;
      case 'chips':
      case 'chip':
      case 'multiselect':
      case 'multi_select':
        return FieldType.chips;
      case 'date':
      case 'datepicker':
      case 'date_picker':
        return FieldType.date;
      case 'time':
      case 'timepicker':
      case 'time_picker':
        return FieldType.time;
      case 'datetime':
      case 'date_time':
      case 'datetimepicker':
      case 'date_time_picker':
        return FieldType.dateTime;
      case 'group':
      case 'section':
      case 'nested':
      case 'fieldset':
        return FieldType.group;
      case 'repeatable':
      case 'repeater':
      case 'list':
      case 'array':
        return FieldType.repeatable;
      case 'image':
      case 'imagepicker':
      case 'image_picker':
      case 'photo':
        return FieldType.image;
      case 'file':
      case 'filepicker':
      case 'file_picker':
      case 'attachment':
        return FieldType.file;
      case 'camera':
      case 'capture':
        return FieldType.camera;
      case 'location':
      case 'geo':
      case 'geolocation':
      case 'gps':
        return FieldType.location;
      case 'slider':
        return FieldType.slider;
      case 'rangeslider':
      case 'range_slider':
      case 'range':
        return FieldType.rangeSlider;
      case 'rating':
      case 'stars':
        return FieldType.rating;
      case 'signature':
      case 'sign':
        return FieldType.signature;
      case 'color':
      case 'colorpicker':
      case 'color_picker':
        return FieldType.color;
      case 'custom':
        return FieldType.custom;
      default:
        return FieldType.unknown;
    }
  }
}

/// Built-in validator kinds that can be declared in JSON.
enum ValidatorType {
  /// Field must not be empty / null.
  required,

  /// Value must look like an email address.
  email,

  /// Value must look like a phone number.
  phone,

  /// Value must match a regular expression.
  regex,

  /// String length constraints.
  length,

  /// Numeric / comparable minimum.
  min,

  /// Numeric / comparable maximum.
  max,

  /// Compare against another field.
  compare,

  /// Named async validator (Phase 4).
  async,

  /// Server / remote validator (Phase 4).
  server,

  /// Custom / unknown validator key.
  custom;

  /// Parses a string into a [ValidatorType].
  static ValidatorType fromString(String? value) {
    if (value == null || value.isEmpty) return ValidatorType.custom;
    switch (value.toLowerCase().trim()) {
      case 'required':
        return ValidatorType.required;
      case 'email':
        return ValidatorType.email;
      case 'phone':
      case 'tel':
        return ValidatorType.phone;
      case 'regex':
      case 'pattern':
        return ValidatorType.regex;
      case 'length':
        return ValidatorType.length;
      case 'min':
      case 'minimum':
        return ValidatorType.min;
      case 'max':
      case 'maximum':
        return ValidatorType.max;
      case 'compare':
      case 'match':
      case 'equals_field':
        return ValidatorType.compare;
      case 'async':
        return ValidatorType.async;
      case 'server':
      case 'remote':
      case 'api':
        return ValidatorType.server;
      default:
        return ValidatorType.custom;
    }
  }
}

/// Comparison operators used by conditions and compare validators.
enum ConditionOperator {
  /// Equal.
  equals,

  /// Not equal.
  notEquals,

  /// Greater than (numeric / comparable).
  greaterThan,

  /// Greater than or equal.
  greaterThanOrEqual,

  /// Less than.
  lessThan,

  /// Less than or equal.
  lessThanOrEqual,

  /// String / list contains.
  contains,

  /// Value is empty / null.
  isEmpty,

  /// Value is not empty.
  isNotEmpty,

  /// Value is in a list.
  isIn;

  /// Parses an operator from common JSON aliases.
  static ConditionOperator fromString(String? value) {
    if (value == null || value.isEmpty) return ConditionOperator.equals;
    switch (value.toLowerCase().trim()) {
      case 'eq':
      case '==':
      case 'equals':
      case 'equal':
        return ConditionOperator.equals;
      case 'neq':
      case 'ne':
      case '!=':
      case 'notequals':
      case 'not_equals':
        return ConditionOperator.notEquals;
      case 'gt':
      case '>':
      case 'greaterthan':
      case 'greater_than':
        return ConditionOperator.greaterThan;
      case 'gte':
      case '>=':
      case 'greaterthanorequal':
      case 'greater_than_or_equal':
        return ConditionOperator.greaterThanOrEqual;
      case 'lt':
      case '<':
      case 'lessthan':
      case 'less_than':
        return ConditionOperator.lessThan;
      case 'lte':
      case '<=':
      case 'lessthanorequal':
      case 'less_than_or_equal':
        return ConditionOperator.lessThanOrEqual;
      case 'contains':
      case 'include':
      case 'includes':
        return ConditionOperator.contains;
      case 'empty':
      case 'isempty':
      case 'is_empty':
        return ConditionOperator.isEmpty;
      case 'notempty':
      case 'isnotempty':
      case 'is_not_empty':
        return ConditionOperator.isNotEmpty;
      case 'in':
      case 'isin':
      case 'is_in':
        return ConditionOperator.isIn;
      default:
        return ConditionOperator.equals;
    }
  }
}
