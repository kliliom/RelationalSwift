//
//  AlterTableChange.swift
//  Created by Kristof Liliom in 2024.
//

/// Base protocol for all alter table changes.
public protocol AlterTableChange: Change, SQLConvertible {}