=begin
WSDL4R - Creating driver code from WSDL.
Copyright (C) 2002 NAKAMURA Hiroshi.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PRATICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 675 Mass
Ave, Cambridge, MA 02139, USA.
=end


require 'wsdl/info'
require 'wsdl/soap/methodDefCreatorSupport'


module WSDL
  module SOAP


class MethodDefCreator
  include MethodDefCreatorSupport

  attr_reader :definitions

  def initialize( definitions )
    @definitions = definitions
    @complexTypes = @definitions.complexTypes
    @types = nil
  end

  def dump( portType )
    @types = []
    result = ""
    operations = @definitions.getPortType( portType ).operations
    binding = @definitions.getPortTypeBinding( portType )
    operations.each do | operation |
      opBinding = binding.operations[ operation.name ]
      result << ",\n" unless result.empty?
      result << dumpMethod( operation, opBinding )
    end
    return result, @types
  end

private

  # methodNameAs, methodName, params, soapAction, namespace
  def dumpMethod( operation, binding )
    methodName = createMethodName( operation.name.name )
    methodNameAs = methodName
    params = collectParams( operation )
    soapAction = binding.soapOperation.soapAction
    namespace = binding.input.soapBody.namespace
    ary2str( [ methodNameAs, methodName, params, soapAction, namespace ] )
  end

  def collectParams( operation )
    inParam = @definitions.getMessage( operation.input.message )
    outParam = @definitions.getMessage( operation.output.message )
    result = inParam.parts.collect { | part |
      collectTypes( part.type )
      paramSet( 'in', typeDef( part.type ), part.name )
    }
    if outParam.parts.size > 0
      retval = outParam.parts[ 0 ]
      collectTypes( retval.type )
      result << paramSet( 'retval', typeDef( retval.type ), retval.name )
      cdr( outParam.parts ).each { | part |
	collectTypes( part.type )
	result << paramSet( 'out', typeDef( part.type ), part.name )
      }
    end
    sortParameterOrder( operation, result )
  end

  def typeDef( type )
    "#{ createClassName( type ) } #{ type }"
  end

  def paramSet( ioType, type, name )
    [ ioType, type, name ]
  end

  def sortParameterOrder( operation, params )
    parameterOrder = operation.parameterOrder
    return params unless parameterOrder
    result = []
    parameterOrder.each do | orderItem |
      paramDef = params.find { | param | param[ 2 ] == orderItem }
      raise unless paramDef
      result << paramDef
    end
    result
  end

  def collectTypes( type )
    @types << type
    return unless @complexTypes[ type ]
    content = @complexTypes[ type ].content
    return unless content
    content.elements.each do | element |
      collectTypes( element.type )
    end
  end

  def ary2str( ary )
    "[ " << ary.collect { | item |
      item.is_a?( Array ) ? ary2str( item ) : dq( item )
    }.join( ", " ) << " ]"
  end

  def dq( ele )
    "\"" << ele << "\""
  end

  def cdr( ary )
    result = ary.dup
    result.shift
    result
  end
end


  end
end
