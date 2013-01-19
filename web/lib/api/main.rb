# web/lib/api/main.rb
class Taginfo < Sinatra::Base

    api(2, 'site', {
        :superseded_by => '4/site',
        :description => 'Get information about this taginfo site.',
        :result => {
            :url         => :STRING,
            :name        => :STRING,
            :description => :STRING,
            :icon        => :STRING,
            :contact     => :STRING,
            :area        => :STRING
        },
        :example => { }
    }) do
        data = {}
        [:url, :name, :description, :icon, :contact, :area].each do |k|
            data[k] = TaginfoConfig.get("instance.#{k}") 
        end
        return data.to_json
    end

end
