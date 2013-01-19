# web/lib/ui/keys_tags.rb
class Taginfo < Sinatra::Base

    get %r{^/keys/(.*)} do |key|
        if params[:key].nil?
            @key = key
        else
            @key = params[:key]
        end

        @key_uri  = escape(@key)

        @title = [escape_html(@key), t.osm.keys]
        section :keys

        @filter_type = get_filter()
        @sel = Hash.new('')
        @sel[@filter_type] = ' selected="selected"'
        @filter_xapi = { 'all' => '*', nil => '*', 'nodes' => 'node', 'ways' => 'way', 'relations' => 'relation' }[@filter_type];

        @count_all_values = @db.select("SELECT count_#{@filter_type} FROM db.keys").condition('key = ?', @key).get_first_value().to_i

        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang=? AND key=? AND value IS NULL", r18n.locale.code, @key).get_first_value())
        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value IS NULL", @key).get_first_value()) if @desc == ''
        if @desc == ''
            @desc = "<span class='empty'>#{ t.pages.key.no_description_in_wiki }</span>"
        else
            @desc = "<span title='#{ t.pages.key.description_from_wiki }' tipsy='w'>#{ @desc }</span>"
        end

        @db.select("SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.wikipages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang=? AND key=? AND value IS NULL UNION SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.wikipages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang='en' AND key=? AND value IS NULL LIMIT 1", r18n.locale.code, @key, @key).
            execute() do |row|
                @image_url = build_image_url(row)
            end

        @prevalent_values = @db.select("SELECT value, count_#{@filter_type} AS count FROM tags").
            condition('key=?', @key).
            condition('count > ?', @count_all_values * 0.02).
            order_by([:count], 'DESC').
            execute().map{ |row| { 'value' => row['value'], 'count' => row['count'].to_i } }

        # add "(other)" label for the rest of the values
        sum = @prevalent_values.inject(0){ |sum, x| sum += x['count'] }
        if sum < @count_all_values
            @prevalent_values << { 'value' => '(other)', 'count' => @count_all_values - sum }
        end

        @josm_count = @db.count('josm_style_rules').condition('k = ?', @key).get_first_value().to_i
        @wiki_count = @db.count('wiki.wikipages').condition('value IS NULL').condition('key=?', @key).get_first_value().to_i
        @user_count = @db.select('SELECT users_all FROM db.keys').condition('key=?', @key).get_first_value().to_i
        
#        (@merkaartor_type, @merkaartor_link, @merkaartor_selector) = @db.select('SELECT tag_type, link, selector FROM merkaartor.keys').condition('key=?', @key).get_columns(:tag_type, :link, :selector)
#        @merkaartor_images = [:node, :way, :area, :relation].map{ |type|
#            name = type.to_s.capitalize
#            '<img src="/img/types/' + (@merkaartor_selector =~ /Type is #{name}/ ? type.to_s : 'none') + '.16.png" width="16" height="16" alt="' + name + '" title="' + name + '"/>'
#        }.join('&nbsp;')
#
#        @merkaartor_values = @db.select('SELECT value FROM merkaartor.tags').condition('key=?', @key).order_by([:value], 'ASC').execute().map{ |row| row['value'] }
#
#        @merkaartor_desc = @db.select('SELECT lang, description FROM key_descriptions').condition('key=?', @key).order_by([:lang], 'DESC').execute()

        @img_width  = TaginfoConfig.get('geodistribution.width')  * TaginfoConfig.get('geodistribution.scale_image')
        @img_height = TaginfoConfig.get('geodistribution.height') * TaginfoConfig.get('geodistribution.scale_image')

        javascript_for(:flexigrid, :d3)
        javascript "#{ r18n.locale.code }/key"
        erb :key
    end

    #-------------------------------------

    get %r{^/tags/(.*)} do |tag|
        if tag.match(/=/)
            kv = tag.split('=', 2)
        else
            kv = [ tag, '' ]
        end
        if params[:key].nil?
            @key = kv[0]
        else
            @key = params[:key]
        end
        if params[:value].nil?
            @value = kv[1]
        else
            @value = params[:value]
        end
        @tag = @key + '=' + @value

        @key_uri  = escape(@key)

        @title = [escape_html(@key) + '=' + escape_html(@value), t.osm.tags]
        section :tags

        @filter_type = get_filter()
        @sel = Hash.new('')
        @sel[@filter_type] = ' selected="selected"'
        @filter_xapi = { 'all' => '*', nil => '*', 'nodes' => 'node', 'ways' => 'way', 'relations' => 'relation' }[@filter_type];

        @josm_count = @db.count('josm_style_rules').condition('k = ?', @key).condition('v = ?', @value).get_first_value().to_i
        @wiki_count = @db.count('wiki.wikipages').condition('key=?', @key).condition('value=?', @value).get_first_value().to_i
        if @wiki_count == 0
            @wiki_count_key = @db.count('wiki.wikipages').condition('key=?', @key).condition('value IS NULL').get_first_value().to_i
        end
        @count_all = @db.select("SELECT count_#{@filter_type} FROM db.tags").condition('key = ? AND value = ?', @key, @value).get_first_value().to_i

        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang=? AND key=? AND value=?", r18n.locale.code, @key, @value).get_first_value())
        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value=?", @key, @value).get_first_value()) if @desc == ''
        if @desc == ''
            @desc = "<span class='empty'>#{ t.pages.tag.no_description_in_wiki }</span>"
        else
            @desc = "<span title='#{ t.pages.tag.description_from_wiki }' tipsy='w'>#{ @desc }</span>"
        end

        @db.select("SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.wikipages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang=? AND key=? AND value=? UNION SELECT width, height, image_url, thumb_url_prefix, thumb_url_suffix FROM wiki.wikipages LEFT OUTER JOIN wiki.wiki_images USING(image) WHERE lang='en' AND key=? AND value=? LIMIT 1", r18n.locale.code, @key, @value, @key, @value).
            execute() do |row|
                @image_url = build_image_url(row)
            end

        javascript_for(:flexigrid)
        javascript "#{ r18n.locale.code }/tag"
        erb :tag
    end

end

