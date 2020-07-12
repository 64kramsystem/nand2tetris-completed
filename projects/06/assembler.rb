#!/usr/bin/env ruby

require 'byebug'
require 'English'
require 'pp'

PREDEFINED_SYMBOLS = {
  'R0' => 0,
  'R1' => 1,
  'R2' => 2,
  'R3' => 3,
  'R4' => 4,
  'R5' => 5,
  'R6' => 6,
  'R7' => 7,
  'R8' => 8,
  'R9' => 9,
  'R10' => 10,
  'R11' => 11,
  'R12' => 12,
  'R13' => 13,
  'R14' => 14,
  'R15' => 15,
  'SCREEN' => 16384,
  'KBD' => 24576,
  'SP' => 0,
  'LCL' => 1,
  'ARG' => 2,
  'THIS' => 3,
  'THAT' => 4,
}.freeze

def decode_cmdline_options(debug: true)
  if ARGV.size != 2 || %w[-h --help].include?(ARGV[0])
    puts "Usage: assembler.rb <asm_filename> <hack_filename>"
    exit
  end

  ARGV[0..1].tap { |o| puts "==========", "Asm file: #{o[0]}, Hack file: #{o[1]}" if debug }
end

def extract_tokens(asm_file, debug: true)
  IO
    .readlines(asm_file)
    .map { |line| line.sub(%r[//.*], '') }
    .map { |line| line.strip }
    .delete_if { |line| line == "" }
    .tap { |o| puts "==========", "Tokens:", o if debug }
end

def prepare_symbols_table(tokens, debug: true)
  symbols_table = PREDEFINED_SYMBOLS.dup
  current_free_location = 16

  tokens.inject(0) do |program_location, token|
    case token
    when /^\(.+\)/
      label = $MATCH[1..-2]

      symbols_table[label] = program_location

      # don't increment! a label is not an instruction
    else
      program_location += 1
    end

    program_location
  end

  tokens.inject([0, 16]) do |(program_location, first_free_location), token|
    case token
    when /^\(.+\)/
      # don't increment! a label is not an instruction
    when /^@\d+$/
      # literal assignment

      program_location += 1
    when /^@.+/
      label = $MATCH[1..-1]

      if !symbols_table.key?(label)
        symbols_table[label] = first_free_location
        first_free_location += 1
      end

      program_location += 1
    else
      program_location += 1
    end

    [program_location, first_free_location]
  end

  symbols_table.tap do |o|
    puts "==========", "Symbols table:"
    pp o.select { |k, _| ! PREDEFINED_SYMBOLS.key?(k) }.sort_by { |_, v| v}.to_h
  end
end

def parse_instructions(tokens, symbols_table, debug: true)
  binary_code = String.new

  tokens.inject(1) do |instruction_num, token|
    case token
    when /^\(/
      # Label; do nothing
      next instruction_num
    when /^@.*/
      symbol = $MATCH[1..-1]

      instruction_int = encode_a_instruction(symbol, symbols_table)
      instruction_num += 1
    when /^(.+=)?(.+?)(;.+)?$/
      dest, comp, jump = $LAST_MATCH_INFO[1..3]
      dest = dest[0..-2] if dest
      jump = jump[1..-1] if jump

      instruction_int = encode_c_instruction(dest, comp, jump)
      instruction_num += 1
    else
      raise "Token: #{token}"
    end

    binary_code << instruction_int << "\n"

    instruction_num
  end

  binary_code.tap { |o| puts "==========", "Binary:", o if debug }
end

# Returns a 16-chars long binary string.
#
def encode_a_instruction(symbol, symbols_table)
  if symbol =~ /^\d+$/
    value = symbol.to_i
  else
    value = symbols_table.fetch(symbol)
  end

  "%016b" % value
end

# Returns a 16-chars long binary string.
#
def encode_c_instruction(dest, comp, jump)
  instruction_bits = '111' # fixed

  # A-bit

  if comp =~ /M/
    instruction_bits << '1'
  else
    instruction_bits << '0'
  end

  # Comp

  instruction_bits <<
    case comp.sub('M', 'A')
    when '0'
      '101010'
    when '1'
      '111111'
    when '-1'
      '111010'
    when 'D'
      '001100'
    when 'A'
      '110000'
    when '!D'
      '001101'
    when '!A'
      '110001'
    when '-D'
      '001111'
    when '-A'
      '110011'
    when 'D+1'
      '011111'
    when 'A+1'
      '110111'
    when 'D-1'
      '001110'
    when 'A-1'
      '110010'
    when 'D+A'
      '000010'
    when 'D-A'
      '010011'
    when 'A-D'
      '000111'
    when 'D&A'
      '000000'
    when 'D|A'
      '010101'
    else
      raise "comp: #{comp}"
    end

  # Dest

  instruction_bits << (dest&.match(/A/) ? '1' : '0')
  instruction_bits << (dest&.match(/D/) ? '1' : '0')
  instruction_bits << (dest&.match(/M/) ? '1' : '0')

  # Jump

  instruction_bits <<
    case jump
    when nil
      '000'
    when 'JGT'
      '001'
    when 'JEQ'
      '010'
    when 'JGE'
      '011'
    when 'JLT'
      '100'
    when 'JNE'
      '101'
    when 'JLE'
      '110'
    when 'JMP'
      '111'
    else
      raise "Jump: #{jump}"
    end

  instruction_bits
end

if $PROGRAM_NAME == $0
  asm_file, hack_file = decode_cmdline_options(debug: false)
  tokens = extract_tokens(asm_file, debug: false)
  symbols_table = prepare_symbols_table(tokens)
  binary_code = parse_instructions(tokens, symbols_table, debug: false)
  IO.write(hack_file, binary_code)
end
