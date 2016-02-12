// Copyright (c) 2015, the Dart Team. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in
// the LICENSE file.

// This file defines the same types as sdk/lib/mirrors/mirrors.dart, in
// order to enable code using [dart:mirrors] to switch to using
// [Reflectable] based mirrors with a small porting effort. The changes are
// discussed below, under headings on the form 'API Change: ..'.

// API Change: Incompleteness.
//
// Compared to the corresponding classes in [dart:mirrors], a number of
// classes have been omitted and some methods have been omitted from some
// classes, based on the needs arising in concrete examples.  Additional
// methods may be added later if the need arises and if they can be
// implemented.  These missing elements are indicated by comments on the
// form '// Currently skip ..' in the code below.

// API Change: Returning non-mirrors.
//
// We took the opportunity to change the returned values of reflective
// operations from mirrors to base values. E.g., [invoke] in [ObjectMirror]
// has return type [Object] rather than [InstanceMirror].  If myObjectMirror
// is an [ObjectMirror] then evaluation of, e.g., myObjectMirror.invoke(..)
// yields the same result as that of myObjectMirror.invoke(..).reflectee in
// [dart:mirrors].  The point is that returning base values may be cheaper in
// typical scenarios (no mirror objects created, and they were never used
// anyway) and there is no loss of information (we can get a mirror on the
// returned value). So we move from the "pure" design where the reflective
// level is always preserved to a "practical" model where we return to the
// base level in selected cases.
//
// These selected cases are [invoke], [getField], and [setField] in
// [ObjectMirror], [newInstance] in [ClassMirror], and [defaultValue] in
// [ParameterMirror], where the return type has been changed from
// [InstanceMirror] to [Object]. Similarly, the return type for [metadata]
// in [DeclarationMirror] and in [LibraryDependencyMirror] was changed from
// `List<InstanceMirror>` to `List<Object>`.  The relevant locations in the
// code below have been marked with comments on the form
// '// RET: <old-return-type>' resp. '// TYARG: <old-type-argument>' and the
// discrepancies are mentioned in the relevant class dartdoc.
//
// TODO(eernst) doc: The information given in the previous paragraph
// should be made part of the dartdoc comments on each of the relevant
// methods; since those comments will now differ from the ones in
// dart:mirrors, we should copy them all and add the discrepancies.
//
// A similar change could have been applied to many other methods, but
// in those cases it seems more likely that the mirror will be used
// in its own right rather than just to get 'theMirror.reflectee'.
// Some of these locations are marked with '// Possible'.  They are in
// general concerned with types in a broad sense: [ClassMirror],
// [TypeMirror], and [LibraryMirror].

// TODO(eernst) doc: The preceeding comment blocks should be made a dartdoc
// on the library when/if such dartdoc comments are supported.
// TODO(eernst) doc: Change the preceeding comment to use a more
// user-centric style.

// TODO(eernst) doc: This is a Meta-TODO, adding detail to several TODOs below
// saying 'make this .. more user friendly' as well as the comment above
// saying 'more user-centric'. All those "not-so-friendly" comments originate
// in the `mirrors.dart` file that implements the `dart:mirrors` library, so
// missing dartdoc comments in this file would typically be taken from
// there and then adjusted to match the preferred style in this library.
// The following points should be kept in mind in this adjustment process:
//   1. The documentation from `dart:mirrors` is too abstract for typical
// programmers (it is in a near-spec style), so maybe that kind of
// documentation should be provided in a separate location, and the
// documentation that programmers get to see first will be example based
// and less abstract.
//   2. Formatting: *name* is used to indicate pseudo-semantic entities
// such as objects (that may or may not be the value of a known expression)
// and meta-variables for identifiers, etc. This is explained in the
// documentation for `dart:mirrors` (search 'Dart pseudo-code' on
// https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/dart:mirrors)
//   3. Semantic precision may be pointless in cases where the underlying
// concepts are obvious; having an example based frontmost layer and a more
// spec-styled layer behind it would be helpful with this as well, because
// the example layer could be quite simple.
//   4. Considering `invokeGetter`, the example based approach could be
// similar to the following:
//
//   Invokes a getter and returns the result. Conceptually, this function is
//   equivalent to `this.reflectee.name` where the `name` identifier is the
//   value of the given [getterName].
//
//   Example:
//     var m = reflectable.reflect(o);
//     m.invokeGetter("foo");  // Equivalent to o.foo.
//
//   (then give more detail if the simple explanation above needs it).

/// Basic reflection in Dart,
/// with support for introspection and dynamic invocation.
///
/// *Introspection* is that subset of reflection by which a running
/// program can examine its own structure. For example, a function
/// that prints out the names of all the members of an arbitrary object.
///
/// *Dynamic invocation* refers the ability to evaluate code that
/// has not been literally specified at compile time, such as calling a method
/// whose name is provided as an argument (because it is looked up
/// in a database, or provided interactively by the user).
///
/// ## How to interpret this library's documentation
///
/// The documentation frequently abuses notation with
/// Dart pseudo-code such as [:o.x(a):], where
/// o and a are defined to be objects; what is actually meant in these
/// cases is [:o'.x(a'):] where *o'* and *a'* are Dart variables
/// bound to *o* and *a* respectively. Furthermore, *o'* and *a'*
/// are assumed to be fresh variables (meaning that they are
/// distinct from any other variables in the program).
///
/// Sometimes the documentation refers to *serializable* objects.
/// An object is serializable across isolates if and only if it is an instance
/// of num, bool, String, a list of objects that are serializable
/// across isolates, or a map with keys and values that are all serializable
/// across isolates.
library reflectable.mirrors;

// Currently skip 'abstract class MirrorSystem': represented by reflectors.

// Currently skip 'external MirrorSystem currentMirrorSystem': represented by
// reflectors.

// Omit 'external InstanceMirror reflect': method on reflectors.

// Currently skip 'external ClassMirror reflectClass'.

// Omit 'external TypeMirror reflectType': method on reflectors.

/// The base class for all mirrors.
abstract class Mirror {}

// Currently skip 'abstract class IsolateMirror implements Mirror'.

/// A [DeclarationMirror] reflects some entity declared in a Dart program.
abstract class DeclarationMirror implements Mirror {
  /// The simple name for this Dart language entity.
  ///
  /// The simple name is in most cases the the identifier name of the entity,
  /// such as 'myMethod' for a method, [:void myMethod() {...}:] or 'mylibrary'
  /// for a [:library 'mylibrary';:] declaration.
  String get simpleName;

  /// The fully-qualified name for this Dart language entity.
  ///
  /// This name is qualified by the name of the owner. For instance,
  /// the qualified name of a method 'method' in class 'Class' in
  /// library 'library' is 'library.Class.method'.
  ///
  /// Returns a [Symbol] constructed from a string representing the
  /// fully qualified name of the reflectee.
  /// Let *o* be the [owner] of this mirror, let *r* be the reflectee of
  /// this mirror, let *p* be the fully qualified
  /// name of the reflectee of *o*, and let *s* be the simple name of *r*
  /// computed by [simpleName].
  /// The fully qualified name of *r* is the
  /// concatenation of *p*, '.', and *s*.
  ///
  /// Because an isolate can contain more than one library with the same name
  /// (at different URIs), a fully-qualified name does not uniquely identify
  /// any language entity.
  String get qualifiedName;

  /// A mirror on the owner of this Dart language entity.
  ///
  /// The owner is the declaration immediately surrounding the reflectee:
  ///
  /// * For a library, the owner is [:null:].
  /// * For a class declaration, typedef or top level function or variable, the
  ///   owner is the enclosing library.
  /// * For a mixin application `S with M`, the owner is the owner of `M`.
  /// * For a constructor, the owner is the immediately enclosing class.
  /// * For a method, instance variable or a static variable, the owner is the
  ///   immediately enclosing class, unless the class is a mixin application
  ///   `S with M`, in which case the owner is `M`. Note that `M` may be an
  ///   invocation of a generic.
  /// * For a parameter, local variable or local function the owner is the
  ///   immediately enclosing function.
  DeclarationMirror get owner;

  /// Whether this declaration is library private.
  ///
  /// Always returns `false` for a library declaration,
  /// otherwise returns `true` if the declaration's name starts with an
  /// underscore character (`_`), and `false` if it doesn't.
  bool get isPrivate;

  /// Whether this declaration is top-level.
  ///
  /// A declaration is considered top-level if its [owner] is a [LibraryMirror].
  bool get isTopLevel;

  /// The source location of this Dart language entity, or [:null:] if the
  /// entity is synthetic.
  ///
  /// If the reflectee is a variable, the returned location gives the position
  /// of the variable name at its point of declaration.
  ///
  /// If the reflectee is a library, class, typedef, function or type variable
  /// with associated metadata, the returned location gives the position of the
  /// first metadata declaration associated with the reflectee.
  ///
  /// Otherwise:
  ///
  /// If the reflectee is a library, the returned location gives the position of
  /// the keyword 'library' at the reflectee's point of declaration, if the
  /// reflectee is a named library, or the first character of the first line in
  /// the compilation unit defining the reflectee if the reflectee is anonymous.
  ///
  /// If the reflectee is an abstract class, the returned location gives the
  /// position of the keyword 'abstract' at the reflectee's point of declaration.
  /// Otherwise, if the reflectee is a class, the returned location gives the
  /// position of the keyword 'class' at the reflectee's point of declaration.
  ///
  /// If the reflectee is a typedef the returned location gives the position of
  /// the of the keyword 'typedef' at the reflectee's point of declaration.
  ///
  /// If the reflectee is a function with a declared return type, the returned
  /// location gives the position of the function's return type at the
  /// reflectee's point of declaration. Otherwise. the returned location gives
  /// the position of the function's name at the reflectee's point of
  /// declaration.
  ///
  /// This operation is optional and may throw an [UnsupportedError].
  SourceLocation get location;

  /// A list of the metadata associated with this declaration.
  ///
  /// Let *D* be the declaration this mirror reflects.
  /// If *D* is decorated with annotations *A1, ..., An*
  /// where *n > 0*, then for each annotation *Ai* associated
  /// with *D, 1 <= i <= n*, let *ci* be the constant object
  /// specified by *Ai*. Then this method returns a list whose
  /// members *c1, ..., cn*. If no annotations are associated
  /// with *D*, then an empty list is returned.
  ///
  /// If evaluating any of *c1, ..., cn* would cause a compilation error
  /// the effect is the same as if a non-reflective compilation error
  /// had been encountered.
  ///
  /// Note that the return type of the corresponding method in
  /// dart:mirrors is List<InstanceMirror>.
  //
  // TODO(eernst) doc: Make this comment more user friendly.
  // TODO(eernst) implement: Include comments as `metadata`, remember to
  // indicate which ones are doc comments (`isDocComment`),
  // cf. https://github.com/dart-lang/reflectable/issues/3.
  // Note that we may wish to represent a comment as an
  // instance of [Comment] from reflectable/mirrors.dart,
  // which is required in order to indicate explicitly that it is
  // a doc comment; or we may decide that this violation of the
  // "return a base object, not a mirror" rule is unacceptable, and
  // return a [String], thus requiring the receiver to determine
  // whether or not it is a doc comment, based on the contents
  // of the [String].
  // Remark from sigurdm@ on this topic, 2015/03/19 09:50:06: We
  // could also consider extending the interface with a
  // `docComments` or similar.  To me it is highly confusing that
  // metadata returns comments.  But if dart:mirrors does this we
  // might just want to follow along.
  List<Object> get metadata; // TYARG: InstanceMirror
}

/// An [ObjectMirror] is a common superinterface of [InstanceMirror],
/// [ClassMirror], and [LibraryMirror] that represents their shared
/// functionality.
///
/// For the purposes of the mirrors library, these types are all
/// object-like, in that they support method invocation and field
/// access.  Real Dart objects are represented by the [InstanceMirror]
/// type.
///
/// See [InstanceMirror], [ClassMirror], and [LibraryMirror].
abstract class ObjectMirror implements Mirror {

  /// Invokes the function or method [memberName], and returns the result.
  ///
  /// Let *o* be the object reflected by this mirror, let
  /// *f* be the simple name of the member denoted by [memberName],
  /// let *a1, ..., an* be the elements of [positionalArguments]
  /// let *k1, ..., km* be the identifiers denoted by the elements of
  /// [namedArguments.keys]
  /// and let *v1, ..., vm* be the elements of [namedArguments.values].
  /// Then this method will perform the method invocation
  ///  *o.f(a1, ..., an, k1: v1, ..., km: vm)*
  /// in a scope that has access to the private members
  /// of *o* (if *o* is a class or library) or the private members of the
  /// class of *o* (otherwise).
  /// If the invocation returns a result *r*, this method returns
  /// the result *r*.
  /// If the invocation causes a compilation error
  /// the effect is the same as if a non-reflective compilation error
  /// had been encountered.
  /// If the invocation throws an exception *e* (that it does not catch)
  /// this method throws *e*.
  ///
  /// Note that the return type of the corresponding method in
  /// dart:mirrors is [InstanceMirror].
  //
  // TODO(eernst) doc: make this comment more user friendly.
  // TODO(eernst) doc: revise language on private members when semantics known.
  Object invoke(String memberName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]); // RET: InstanceMirror

  /// Invokes a getter and returns the result. The getter can be the
  /// implicit getter for a field, or a user-defined getter method.
  ///
  /// Let *o* be the object reflected by this mirror, let
  /// *f* be the simple name of the getter denoted by [fieldName],
  /// Then this method will perform the getter invocation
  ///  *o.f*
  /// in a scope that has access to the private members
  /// of *o* (if *o* is a class or library) or the private members of the
  /// class of *o* (otherwise).
  ///
  /// If this mirror is an [InstanceMirror], and [fieldName] denotes an instance
  /// method on its reflectee, the result of the invocation is a closure
  /// corresponding to that method.
  ///
  /// If this mirror is a [LibraryMirror], and [fieldName] denotes a top-level
  /// method in the corresponding library, the result of the invocation is a
  /// closure corresponding to that method.
  ///
  /// If this mirror is a [ClassMirror], and [fieldName] denotes a static method
  /// in the corresponding class, the result of the invocation is a closure
  /// corresponding to that method.
  ///
  /// If the invocation returns a result *r*, this method returns
  /// the result *r*.
  /// If the invocation causes a compilation error
  /// the effect is the same as if a non-reflective compilation error
  /// had been encountered.
  /// If the invocation throws an exception *e* (that it does not catch)
  /// this method throws *e*.
  ///
  /// Note that the return type of the corresponding method in
  /// dart:mirrors is [InstanceMirror].
  //
  // TODO(eernst) doc: make this comment more user friendly.
  // TODO(eernst) doc: revise language on private members when semantics known.
  Object invokeGetter(String getterName);

  /// Invokes a setter and returns the result. The setter may be either
  /// the implicit setter for a non-final field, or a user-defined setter
  /// method. The name of the setter can include the final `=`; if it is
  /// not present, it will be added.
  ///
  /// Let *o* be the object reflected by this mirror, let
  /// *f* be the simple name of the getter denoted by [fieldName],
  /// and let *a* be the object bound to [value].
  /// Then this method will perform the setter invocation
  /// *o.f = a*
  /// in a scope that has access to the private members
  /// of *o* (if *o* is a class or library) or the private members of the
  /// class of *o* (otherwise).
  /// If the invocation returns a result *r*, this method returns
  /// the result *r*.
  /// If the invocation causes a compilation error
  /// the effect is the same as if a non-reflective compilation error
  /// had been encountered.
  /// If the invocation throws an exception *e* (that it does not catch)
  /// this method throws *e*.
  ///
  /// Note that the return type of the corresponding method in
  /// dart:mirrors is [InstanceMirror].
  //
  // TODO(eernst) doc: make this comment more user friendly.
  // TODO(eernst) doc: revise language on private members when semantics known.
  Object invokeSetter(String setterName, Object value);
}

/// An [InstanceMirror] reflects an instance of a Dart language object.
abstract class InstanceMirror implements ObjectMirror {

  /// A mirror on the type of the reflectee.
  ///
  /// Returns a mirror on the class of the reflectee, based on the value
  /// returned by [runtimeType]. Note that the actual class of the reflectee
  /// may differ from the object returned by invoking [runtimeType] on
  /// the reflectee, because that method can be overridden. In that case,
  /// please take special care.
  ClassMirror get type;

  /// Whether [reflectee] will return the instance reflected by this mirror.
  ///
  /// A value is simple if one of the following holds:
  ///
  /// * the value is [:null:]
  /// * the value is of type [num]
  /// * the value is of type [bool]
  /// * the value is of type [String]
  bool get hasReflectee;

  /// If the [InstanceMirror] reflects an instance it is meaningful to
  /// have a local reference to, we provide access to the actual
  /// instance here.
  ///
  /// If you access [reflectee] when [hasReflectee] is false, an
  /// exception is thrown.
  get reflectee;

  /// Whether this mirror is equal to [other].
  ///
  /// The equality holds if and only if [other] is a mirror
  /// of the same kind, [hasReflectee] is true, and so is
  /// [:identical(reflectee, other.reflectee):].
  bool operator ==(other);

  /// Performs [invocation] on [reflectee].
  ///
  /// Equivalent to
  ///
  ///     if (invocation.isGetter) {
  ///       return this.invokeGetter(invocation.memberName);
  ///     } else if (invocation.isSetter) {
  ///       return this.invokeGetter(
  ///           invocation.memberName,
  ///           invocation.positionArguments[0]);
  ///     } else {
  ///       return this.invoke(
  ///           invocation.memberName,
  ///           invocation.positionalArguments,
  ///           invocation.namedArguments);
  ///     }
  delegate(Invocation invocation);
}

/// A [ClosureMirror] reflects a closure.
///
/// A [ClosureMirror] provides the ability to execute its reflectee and
/// introspect its function.
abstract class ClosureMirror implements InstanceMirror {

  /// A mirror on the function associated with this closure.
  ///
  /// The function associated with an implicit closure of a function is that
  /// function.
  ///
  /// The function associated with an instance of a class that has a [:call:]
  /// method is that [:call:] method.
  ///
  /// A Dart implementation might choose to create a class for each closure
  /// expression, in which case [:function:] would be the same as
  /// [:type.declarations[#call]:]. But the Dart language model does not 
  /// require this. A more typical implementation involves a single closure 
  /// class for each type signature, where the call method dispatches to a
  /// function held in the closure rather the call method directly implementing
  /// the closure body. So one cannot rely on closures from distinct closure
  /// expressions having distinct classes ([:type:]), but one can rely on
  /// them having distinct functions ([:function:]).
  MethodMirror get function;

  /// Executes the closure and returns a mirror on the result.
  ///
  /// Let *f* be the closure reflected by this mirror,
  /// let *a1, ..., an* be the elements of [positionalArguments],
  /// let *k1, ..., km* be the identifiers denoted by the elements of
  /// [namedArguments.keys],
  /// and let *v1, ..., vm* be the elements of [namedArguments.values].
  ///
  /// Then this method will perform the method invocation
  /// *f(a1, ..., an, k1: v1, ..., km: vm)*.
  ///
  /// If the invocation returns a result *r*, this method returns *r*.
  ///
  /// If the invocation causes a compilation error, the effect is the same as 
  /// if a non-reflective compilation error had been encountered.
  ///
  /// If the invocation throws an exception *e* (that it does not catch), this
  /// method throws *e*.
  Object apply(List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]); // RET: InstanceMirror
}

/// A [LibraryMirror] reflects a Dart language library, providing
/// access to the variables, functions, and classes of the
/// library.
abstract class LibraryMirror implements DeclarationMirror, ObjectMirror {

  /// The absolute uri of the library.
  Uri get uri;

  /// Returns an immutable map of the declarations actually given in the 
  /// library.
  ///
  /// This map includes all regular methods, getters, setters, fields, classes
  /// and typedefs actually declared in the library. The map is keyed by the
  /// simple names of the declarations.
  Map<String, DeclarationMirror> get declarations;


  /// Whether this mirror is equal to [other].
  ///
  /// The equality holds if and only if
  ///
  /// 1. [other] is a mirror of the same kind, and
  /// 2. The library being reflected by this mirror and the library being
  ///    reflected by [other] are the same library in the same isolate.
  bool operator ==(other);

  /// Returns a list of the imports and exports in this library;
  List<LibraryDependencyMirror> get libraryDependencies;
}

/// A mirror on an import or export declaration.
abstract class LibraryDependencyMirror implements Mirror {
  /// Is `true` if this dependency is an import.
  bool get isImport;

  /// Is `true` if this dependency is an export.
  bool get isExport;

  /// Returns true iff this dependency is a deferred import. Otherwise returns
  /// false.
  bool get isDeferred;

  /// Returns the library mirror of the library that imports or exports the
  /// [targetLibrary].
  LibraryMirror get sourceLibrary;

  /// Returns the library mirror of the library that is imported or exported,
  /// or null if the library is not loaded.
  LibraryMirror get targetLibrary;

  /// Returns the prefix if this is a prefixed import and `null` otherwise.
  String get prefix;

  /// Returns the list of show/hide combinators on the import/export
  /// declaration.
  List<CombinatorMirror> get combinators;

  /// Returns the source location for this import/export declaration.
  SourceLocation get location;

  /// Note that the return type of the corresponding method in
  /// dart:mirrors is List<InstanceMirror>.
  List<Object> get metadata; // TYARG: InstanceMirror
}

/// A mirror on a show/hide combinator declared on a library dependency.
abstract class CombinatorMirror implements Mirror {
  /// The list of identifiers on the combinator.
  List<String> get identifiers;

  /// Is `true` if this is a 'show' combinator.
  bool get isShow;

  /// Is `true` if this is a 'hide' combinator.
  bool get isHide;
}

/// A [TypeMirror] reflects a Dart language class, typedef,
/// function type or type variable.
abstract class TypeMirror implements DeclarationMirror {

  /// Returns true if this mirror reflects dynamic, a non-generic class or
  /// typedef, or an instantiated generic class or typedef with support in
  /// the execution mode. Otherwise, returns false.
  ///
  /// The notion of support in the execution mode reflects temporary
  /// restrictions arising from the lack of runtime support for certain
  /// operations. In particular, transformed code cannot produce the reflected
  /// type for an instantiated generic class when one or more type arguments
  /// are or contain type variables from an enclosing class. For instance,
  /// `List<E>` could be used as the type annotation on a variable in the class
  /// `List` itself, and a variable mirror for that method would then deliver
  /// a type mirror for the annotation where `hasReflectedType` is false,
  /// because of the lack of primitives to access the actual type argument of
  /// that list.
  bool get hasReflectedType;

  /// If [hasReflectedType] returns true, returns the corresponding [Type].
  /// Otherwise, an [UnsupportedError] is thrown.
  Type get reflectedType;

  /// An immutable list with mirrors for all type variables for this type.
  ///
  /// If this type is a generic declaration or an invocation of a generic
  /// declaration, the returned list contains mirrors on the type variables
  /// declared in the original declaration.
  /// Otherwise, the returned list is empty.
  ///
  /// This list preserves the order of declaration of the type variables.
  List<TypeVariableMirror> get typeVariables;

  /// An immutable list with mirrors for all type arguments for
  /// this type.
  ///
  /// If the reflectee is an invocation of a generic class,
  /// the type arguments are the bindings of its type parameters.
  /// If the reflectee is the original declaration of a generic,
  /// it has no type arguments and this method returns an empty list.
  /// If the reflectee is not generic, then
  /// it has no type arguments and this method returns an empty list.
  ///
  /// This list preserves the order of declaration of the type variables.
  List<TypeMirror> get typeArguments;

  /// Is this the original declaration of this type?
  ///
  /// For most classes, they are their own original declaration.  For
  /// generic classes, however, there is a distinction between the
  /// original class declaration, which has unbound type variables, and
  /// the instantiations of generic classes, which have bound type
  /// variables.
  bool get isOriginalDeclaration;

  /// A mirror on the original declaration of this type.
  ///
  /// For most classes, they are their own original declaration.  For
  /// generic classes, however, there is a distinction between the
  /// original class declaration, which has unbound type variables, and
  /// the instantiations of generic classes, which have bound type
  /// variables.
  TypeMirror get originalDeclaration;

  // Remark on `isSubtypeOf` signature: Possible ARG: Type.
  // Input from Gilad on this issue:
  // I think we could consider using Type objects as arguments, because that is
  // actually more uniform; in general, the mirror API takes in base level
  // objects and produces meta-level objects. As a practical matter, I'd say we
  // take both.  Union types make that more natural, though there will be some
  // slight cost in checking what kind of argument we get.

  /// Checks the subtype relationship, denoted by `<:` in the language
  /// specification.
  ///
  /// This is the type relationship used in `is` test checks.
  ///
  /// Note that this method can only be invoked successfully if all the
  /// supertypes of the receiver are covered by the reflector, and a
  /// `TypeRelationsCapability` has been requested.
  bool isSubtypeOf(TypeMirror other);

  // Remark on `isAssignableTo` signature: Possible ARG: Type.
  // Input from Gilad on isSubtypeOf is also relevant for this case.

  /// Checks the assignability relationship, denoted by `<=>` in the language
  /// specification.
  /// This is the type relationship tested on assignment in checked mode.
  ///
  /// Note that this method can only be invoked successfully if all the
  /// supertypes of the receiver and [other] are covered by the reflector,
  /// and a `TypeRelationsCapability` has been requested.
  bool isAssignableTo(TypeMirror other);
}

/// A [ClassMirror] reflects a Dart language class.
abstract class ClassMirror implements TypeMirror, ObjectMirror {

  /// A mirror on the superclass on the reflectee.
  ///
  /// If this type is [:Object:], the superclass will be null.
  ClassMirror get superclass;

  /// A list of mirrors on the superinterfaces of the reflectee.
  List<ClassMirror> get superinterfaces;

  /// Is the reflectee abstract?
  bool get isAbstract;

  /// Is the reflectee an enum?
  bool get isEnum;

  /// Returns an immutable map of the declarations actually given in the class
  /// declaration.
  ///
  /// This map includes all regular methods, getters, setters, fields,
  /// constructors and type variables actually declared in the class. Both
  /// static and instance members are included, but no inherited members are
  /// included. The map is keyed by the simple names of the declarations.
  ///
  /// This does not include inherited members.
  Map<String, DeclarationMirror> get declarations;

  /// Returns a map of the methods, getters and setters of an instance of the
  /// class.
  ///
  /// The intent is to capture those members that constitute the API of an
  /// instance. Hence fields are not included, but the getters and setters
  /// implicitly introduced by fields are included. The map includes methods,
  /// getters and setters that are inherited as well as those introduced by the
  /// class itself.
  ///
  /// The map is keyed by the simple names of the members.
  Map<String, MethodMirror> get instanceMembers;

  /// Returns a map of the static methods, getters and setters of the class.
  ///
  /// The intent is to capture those members that constitute the API of a class.
  /// Hence fields are not included, but the getters and setters implicitly
  /// introduced by fields are included.
  ///
  /// The map is keyed by the simple names of the members.
  Map<String, MethodMirror> get staticMembers;

  /// The mixin of this class.
  ///
  /// If this class is the result of a mixin application of the form S with M,
  /// returns a class mirror on M. Otherwise returns a class mirror on
  /// [reflectee].
  ClassMirror get mixin;

  /// Returns true if this mirror reflects dynamic, a non-generic class or
  /// typedef, or an instantiated generic class or typedef with support in
  /// the execution mode. Otherwise, returns false.
  ///
  /// The notion of support in the execution mode reflects temporary
  /// restrictions arising from the lack of runtime support for certain
  /// operations. In particular, untransformed code cannot produce the
  /// dynamic reflected type for a type mirror on an instantiated generic
  /// class due to a lack of primitives for navigation among different
  /// instantiations of the same generic class. For instance, with a given
  /// [Type] representing `List<int>`, there is no support for obtaining
  /// `List<dynamic>` because there are no primitives in 'dart:mirrors'
  /// nor in the core libraries for applying a given generic class to any
  /// given type arguments.
  bool get hasDynamicReflectedType;

  /// If [hasDynamicReflectedType] returns true, returns the [Type] object
  /// representing the fully dynamic instantiation of this class if it is
  /// generic, and return the [Type] object representing this class if it is
  /// not generic. If [hasDynamicReflectedType] returns false it throws an
  /// [UnsupportedError]. The fully dynamic instantiation of a generic class
  /// `C` is the application of `C` to a type argument list of the appropriate
  /// length where every argument is `dynamic`. For instance, the fully dynamic
  /// instantiation of `List` and `Map` is `List<dynamic>` respectively
  /// `Map<dynamic, dynamic>`.
  Type get dynamicReflectedType;

  /// Returns `hasReflectedType || hasDynamicReflectedType`.
  @deprecated
  bool get hasBestEffortReflectedType;

  /// If hasBestEffortReflectedType returns true, returns [reflectedType] if
  /// it is available, otherwise returns [hasDynamicReflectedType]. If
  /// hasBestEffortReflectedType returns false it throws an
  /// [UnsupportedError].
  @deprecated
  Type get bestEffortReflectedType;

  /// Invokes the named constructor and returns the result.
  ///
  /// Let *c* be the class reflected by this mirror
  /// let *a1, ..., an* be the elements of [positionalArguments]
  /// let *k1, ..., km* be the identifiers denoted by the elements of
  /// [namedArguments.keys]
  /// and let *v1, ..., vm* be the elements of [namedArguments.values].
  /// If [constructorName] was created from the empty string
  /// Then this method will execute the instance creation expression
  /// *new c(a1, ..., an, k1: v1, ..., km: vm)*
  /// in a scope that has access to the private members
  /// of *c*. Otherwise, let
  /// *f* be the simple name of the constructor denoted by [constructorName]
  /// Then this method will execute the instance creation expression
  ///  *new c.f(a1, ..., an, k1: v1, ..., km: vm)*
  /// in a scope that has access to the private members
  /// of *c*.
  /// In either case:
  /// If the expression evaluates to a result *r*, this method returns
  /// the result *r*.
  /// If evaluating the expression causes a compilation error
  /// the effect is the same as if a non-reflective compilation error
  /// had been encountered.
  /// If evaluating the expression throws an exception *e*
  /// (that it does not catch)
  /// this method throws *e*.
  ///
  /// Note that the return type of the corresponding method in
  /// dart:mirrors is InstanceMirror.
  //
  // TODO(eernst) doc: make this comment more user friendly.
  // TODO(eernst) doc: revise language on private members when semantics known.
  Object newInstance(String constructorName, List positionalArguments,
      [Map<Symbol, dynamic> namedArguments]); // RET: InstanceMirror

  /// Whether this mirror is equal to [other].
  ///
  /// The equality holds if and only if
  ///
  /// 1. [other] is a mirror of the same kind, and
  /// 2. This mirror and [other] reflect the same class.
  ///
  /// Note that if the reflected class is an invocation of a generic class, 2.
  /// implies that the reflected class and [other] have equal type arguments.
  bool operator ==(other);

  /// Returns whether the class denoted by the receiver is a subclass of the
  /// class denoted by the argument.
  ///
  /// Note that the subclass relationship is reflexive.
  //
  // Possible ARG: Type.
  // Input from Gilad on [TypeMirror#isSubtypeOf] is also relevant for this
  // case.
  bool isSubclassOf(ClassMirror other);

  /// Returns an invoker builder for the given [memberName]. An invoker builder
  /// is a closure that takes an object and returns an invoker for that object.
  /// The returned invoker is a closure that invokes the [memberName] on the
  /// object it is specialized for. In other words, the invoker-builder returns
  /// a tear-off of [memberName] for any given object that implements the
  /// class this [ClassMirror] reflects on.
  ///
  /// Example:
  ///   var invokerBuilder = classMirror.invoker("foo");
  ///   var invoker = invokerBuilder(o);
  ///   invoker(42);  // Equivalent to o.foo(42).
  ///
  /// More precisely, let *c* be the returned closure, let *f* be the simple
  /// name of the member denoted by [memberName], and let *o* be an instance
  /// of the class reflected by this mirror. Consider the following invocation:
  ///  *c(o)(a1, ..., an, k1: v1, ..., km: vm)*
  /// This invocation corresponds to the following non-reflective invocation:
  ///  *o.f(a1, ..., an, k1: v1, ..., km: vm)*
  /// in a scope that has access to the private members
  /// of the class of *o*.
  /// If the invocation returns a result *r*, this method returns
  /// the result *r*.
  /// If the invocation causes a compilation error
  /// the effect is the same as if a non-reflective compilation error
  /// had been encountered.
  /// If the invocation throws an exception *e* (that it does not catch)
  /// this method throws *e*.
  ///
  /// Note that this method is not available in the corresponding dart:mirrors
  /// interface. It was added here because it enables many invocations
  /// of a reflectively chosen method on different receivers using just
  /// one reflective operation, whereas the dart:mirrors interface requires
  /// a reflective operation for each new receiver (which is in practice
  /// likely to mean a reflective operation for each invocation).
  //
  // TODO(eernst) doc: revise language on private members when semantics known.
  Function invoker(String memberName);
}

/// A [FunctionTypeMirror] represents the type of a function in the
/// Dart language.
abstract class FunctionTypeMirror implements ClassMirror {

  /// Returns the return type of the reflectee.
  TypeMirror get returnType;

  /// Returns a list of the parameter types of the reflectee.
  List<ParameterMirror> get parameters;

  /// A mirror on the [:call:] method for the reflectee.
  MethodMirror get callMethod;
}

/// A [TypeVariableMirror] represents a type parameter of a generic type.
abstract class TypeVariableMirror extends TypeMirror {

  /// A mirror on the type that is the upper bound of this type variable.
  TypeMirror get upperBound; // Possible RET: Type

  /// Is the reflectee static?
  /// For the purposes of the mirrors library, type variables are considered
  /// non-static.
  bool get isStatic;

  /// Whether [other] is a [TypeVariableMirror] on the same type variable as 
  /// this mirror.
  ///
  /// The equality holds if and only if
  ///
  /// 1. [other] is a mirror of the same kind, and
  /// 2. [:simpleName == other.simpleName:] and [:owner == other.owner:].
  bool operator ==(other);
}

/// A [TypedefMirror] represents a typedef in a Dart language program.
abstract class TypedefMirror implements TypeMirror {

  /// The defining type for this typedef.
  ///
  /// If the the type referred to by the reflectee is a function type *F*, the
  /// result will be [:FunctionTypeMirror:] reflecting *F* which is abstract
  /// and has an abstract method [:call:] whose signature corresponds to *F*.
  /// For instance [:void f(int):] is the referent for [:typedef void f(int):].
  FunctionTypeMirror get referent;
}

/// A [MethodMirror] reflects a Dart language function, method,
/// constructor, getter, or setter.
abstract class MethodMirror implements DeclarationMirror {

  /// A mirror on the return type for the reflectee.
  TypeMirror get returnType; // Possible RET: Type

  /// Returns the value specified with `hasReflectedType` in [TypeMirror],
  /// but for the return type given by the annotation of the method modeled
  /// by this mirror.
  bool get hasReflectedReturnType;

  /// If [hasReflectedReturnType] is true, returns the corresponding [Type].
  /// Otherwise, an [UnsupportedError] is thrown.
  Type get reflectedReturnType;

  /// Returns the value specified with `hasDynamicReflectedType` in
  /// [ClassMirror], but for the return type given by the annotation of the
  /// method modeled by this mirror.
  bool get hasDynamicReflectedReturnType;

  /// If [hasDynamicReflectedReturnType] is true, returns the corresponding
  /// [Type] as specified for `dynamicReflectedType` in [ClassMirror].
  /// Otherwise, an [UnsupportedError] is thrown.
  Type get dynamicReflectedReturnType;

  /// The source code for the reflectee, if available. Otherwise null.
  String get source;

  /// A list of mirrors on the parameters for the reflectee.
  List<ParameterMirror> get parameters;

  /// A function is considered non-static iff it is permited to refer to 'this'.
  ///
  /// Note that generative constructors are considered non-static, whereas
  /// factory constructors are considered static.
  bool get isStatic;

  /// Is the reflectee abstract?
  bool get isAbstract;

  /// Returns true if the reflectee is synthetic, and returns false otherwise.
  ///
  /// A reflectee is synthetic if it is a getter or setter implicitly introduced
  /// for a field or Type, or if it is a constructor that was implicitly
  /// introduced as a default constructor or as part of a mixin application.
  bool get isSynthetic;

  /// Is the reflectee a regular function or method?
  ///
  /// A function or method is regular if it is not a getter, setter, or
  /// constructor.  Note that operators, by this definition, are
  /// regular methods.
  bool get isRegularMethod;

  /// Is the reflectee an operator?
  bool get isOperator;

  /// Is the reflectee a getter?
  bool get isGetter;

  /// Is the reflectee a setter?
  bool get isSetter;

  /// Is the reflectee a constructor?
  bool get isConstructor;

  /// The constructor name for named constructors and factory methods.
  ///
  /// For unnamed constructors, this is the empty string.  For
  /// non-constructors, this is the empty string.
  ///
  /// For example, [:'bar':] is the constructor name for constructor
  /// [:Foo.bar:] of type [:Foo:].
  String get constructorName;

  /// Is the reflectee a const constructor?
  bool get isConstConstructor;

  /// Is the reflectee a generative constructor?
  bool get isGenerativeConstructor;

  /// Is the reflectee a redirecting constructor?
  bool get isRedirectingConstructor;

  /// Is the reflectee a factory constructor?
  bool get isFactoryConstructor;

  /// Whether this mirror is equal to [other].
  ///
  /// The equality holds if and only if
  ///
  /// 1. [other] is a mirror of the same kind, and
  /// 2. [:simpleName == other.simpleName:] and [:owner == other.owner:].
  bool operator ==(other);
}

/// A [VariableMirror] reflects a Dart language variable declaration.
abstract class VariableMirror implements DeclarationMirror {

  /// Returns a mirror on the type of the reflectee.
  TypeMirror get type; // Possible RET: Type

  /// Returns the value specified with `hasReflectedType` in [TypeMirror],
  /// but for the type given by the annotation of the variable modeled
  /// by this mirror.
  bool get hasReflectedType;

  /// If [hasReflectedType] is true, returns the corresponding [Type].
  /// Otherwise, an [UnsupportedError] is thrown.
  Type get reflectedType;

  /// Returns the value specified with `hasDynamicReflectedType` in
  /// [ClassMirror], but for the type given by the annotation of the
  /// variable modeled by this mirror.
  bool get hasDynamicReflectedType;

  /// If [hasDynamicReflectedType] is true, returns the corresponding
  /// [Type] as specified for `dynamicReflectedType` in [ClassMirror].
  /// Otherwise, an [UnsupportedError] is thrown.
  Type get dynamicReflectedType;

  /// Returns [:true:] if the reflectee is a static variable.
  /// Otherwise returns [:false:].
  ///
  /// For the purposes of the mirror library, top-level variables are
  /// implicitly declared static.
  bool get isStatic;

  /// Returns [:true:] if the reflectee is a final variable.
  /// Otherwise returns [:false:].
  bool get isFinal;

  /// Returns [:true:] if the reflectee is declared [:const:].
  /// Otherwise returns [:false:].
  bool get isConst;

  /// Whether this mirror is equal to [other].
  ///
  /// The equality holds if and only if
  ///
  /// 1. [other] is a mirror of the same kind, and
  /// 2. [:simpleName == other.simpleName:] and [:owner == other.owner:].
  bool operator ==(other);
}

/// A [ParameterMirror] reflects a Dart formal parameter declaration.
abstract class ParameterMirror implements VariableMirror {

  /// A mirror on the type of this parameter.
  TypeMirror get type;

  /// Returns [:true:] if the reflectee is an optional parameter.
  /// Otherwise returns [:false:].
  bool get isOptional;

  /// Returns [:true:] if the reflectee is a named parameter.
  /// Otherwise returns [:false:].
  bool get isNamed;

  /// Returns [:true:] if the reflectee has explicitly declared a default value.
  /// Otherwise returns [:false:].
  bool get hasDefaultValue;

  /// Returns the default value of an optional parameter.
  ///
  /// Returns an [InstanceMirror] on the (compile-time constant)
  /// default value for an optional parameter.
  /// If no default value is declared, it defaults to `null`
  /// and a mirror of `null` is returned.
  ///
  /// Returns `null` for a required parameter.
  Object get defaultValue; // RET: InstanceMirror
}

/// A [SourceLocation] describes the span of an entity in Dart source code.
abstract class SourceLocation {

  /// The 1-based line number for this source location.
  ///
  /// A value of 0 means that the line number is unknown.
  int get line;

  /// The 1-based column number for this source location.
  ///
  /// A value of 0 means that the column number is unknown.
  int get column;

  /// Returns the URI where the source originated.
  Uri get sourceUri;
}

/// Class used for encoding comments as metadata annotations.
class Comment {

  /// The comment text as written in the source text.
  final String text;

  /// The comment text without the start, end, and padding text.
  ///
  /// For example, if [text] is [: /** Comment text. */ :] then the
  /// [trimmedText] is [: Comment text. :].
  final String trimmedText;

  /// Is [:true:] if this comment is a documentation comment.
  ///
  /// That is, that the comment is either enclosed in [: /** ... */ :] or 
  /// starts with [: /// :].
  final bool isDocComment;

  const Comment(this.text, this.trimmedText, this.isDocComment);
}

/// Used to obtain values of type [Type].
///
/// It is sometimes inconvenient to create an expression whose value is an
/// instance of type [Type] representing an instantiated generic type (e.g.,
/// `List<int>` is not an expression `f(List<int>)` is not a method call).
/// This class provides a way to express such values (the example invocation
/// can be written as `f(const TypeValue<List<int>>().type)`).
class TypeValue<E> {
  const TypeValue();
  Type get type => E;
}
