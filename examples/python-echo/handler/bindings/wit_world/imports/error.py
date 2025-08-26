from typing import TypeVar, Generic, Union, Optional, Protocol, Tuple, List, Any, Self
from types import TracebackType
from enum import Flag, Enum, auto
from dataclasses import dataclass
from abc import abstractmethod
import weakref

from ..types import Result, Ok, Err, Some


class Error:
    """
    A resource which represents some error information.
    
    The only method provided by this resource is `to-debug-string`,
    which provides some human-readable information about the error.
    
    In the `wasi:io` package, this resource is returned through the
    `wasi:io/streams/stream-error` type.
    
    To provide more specific error information, other interfaces may
    offer functions to "downcast" this error into more specific types. For example,
    errors returned from streams derived from filesystem types can be described using
    the filesystem's own error-code type. This is done using the function
    `wasi:filesystem/types/filesystem-error-code`, which takes a `borrow<error>`
    parameter and returns an `option<wasi:filesystem/types/error-code>`.
    
    The set of functions which can "downcast" an `error` into a more
    concrete type is open.
    """
    
    def to_debug_string(self) -> str:
        """
        Returns a string that is suitable to assist humans in debugging
        this error.
        
        WARNING: The returned string should not be consumed mechanically!
        It may change across platforms, hosts, or other implementation
        details. Parsing this string is a major platform-compatibility
        hazard.
        """
        raise NotImplementedError
    def __enter__(self) -> Self:
        """Returns self"""
        return self
                                
    def __exit__(self, exc_type: type[BaseException] | None, exc_value: BaseException | None, traceback: TracebackType | None) -> bool | None:
        """
        Release this resource.
        """
        raise NotImplementedError



