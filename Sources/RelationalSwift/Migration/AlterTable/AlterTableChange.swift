//
//  AlterTableChange.swift
//

/// Base protocol for all alter table changes.
public protocol AlterTableChange: Change, SQLBuilderAppendable {}
