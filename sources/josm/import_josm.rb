#!/usr/bin/ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: JOSM
#
#  import_josm.rb
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2013  Jochen Topf <jochen@remote.org>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#------------------------------------------------------------------------------

require 'find'
require 'pp'
require 'sqlite3'
require 'rexml/document'

class Rule

    attr_accessor :k, :v, :b
    attr_accessor :scale_min, :scale_max
    attr_accessor :icon_source
    attr_accessor :line_color, :line_width, :line_realwidth
    attr_accessor :area_color

    attr_reader :rule

    def initialize(rule)
        @rule = rule
    end

    def insert(db)
        db.execute(
            'INSERT INTO josm_style_rules (k, v, b, scale_min, scale_max, icon_source, line_color, line_width, line_realwidth, area_color, rule) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            k,
            v,
            b,
            scale_min,
            scale_max,
            icon_source,
            line_color,
            line_width,
            line_realwidth,
            area_color,
            rule
        )
    end

end

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
db = SQLite3::Database.new(dir + '/taginfo-josm.db')

#------------------------------------------------------------------------------

db.transaction do |db|
    file = File.new(dir + '/elemstyles.xml')
    doc = REXML::Document.new(file)

    doc.elements.each('/rules/rule') do |rule_element|
        rule = Rule.new(rule_element.to_s)
        rule_element.elements.each do |element|
            case element.name
                when 'condition'
                    rule.k = element.attributes['k']
                    rule.v = element.attributes['v']
                    rule.b = element.attributes['b']
                when 'scale_min'
                    rule.scale_min = element.text
                when 'scale_max'
                    rule.scale_max = element.text
                when 'icon'
                    rule.icon_source = element.attributes['src']
                when 'area'
                    rule.area_color = element.attributes['colour']
                when 'line'
                    rule.line_color = element.attributes['colour']
                    rule.line_width = element.attributes['width']
                    rule.line_realwidth = element.attributes['realwidth']
            end
        end
#    pp "rule #{rule.k} #{rule.v}"
        rule.insert(db)
    end
end

db.transaction do |db|
    Dir.chdir(dir + '/svn-source') do
        Dir.foreach(dir + '/svn-source') do |style|
            Find.find(style) do |path|
                if FileTest.directory?(path) && File.basename(path) =~ /^\./
                    Find.prune
                elsif FileTest.file?(path)
                    File.open(path) do |file|
                        png = file.read
                        pathwostyle = path.sub(%r(^#{style}/), '')
                        db.execute('INSERT INTO josm_style_images (style, path, png) VALUES (?, ?, ?)', style, pathwostyle, SQLite3::Blob.new(png))
                    end
                end
            end
        end
    end
end


#-- THE END -------------------------------------------------------------------
