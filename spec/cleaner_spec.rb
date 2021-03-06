require 'cleaner.rb'
require 'flare-docs/htm.rb'

RSpec.describe Cleaner do
  before(:all) do
    @basedir = File.absolute_path('spec/samples')
  end
  let(:cleaner) { Cleaner.new }
  let(:page) { HTM.new base_dir: @basedir, rel_path: 'catalog-flat.htm' }
  context 'when swapping attributes' do
    it 'doesn\'t contain old attribute'  do
      cleaner.swap_attr_values(page, 'bs-callout bs-callout-info', '//p[@class="note"]/@class')
      expect(page.search_by '.note').to be_empty
    end
    it 'contains a new attribute' do
      cleaner.swap_attr_values(page, 'bs-callout bs-callout-info', '//p[@class="note"]/@class')
      expect(page.search_by '[class="bs-callout bs-callout-info"]').not_to be_empty
    end
  end
  context 'when removing attributes with values' do
    it 'removes classes where values begin with specified patterns' do
      cleaner.remove_attribute_with_value(page, 'class', 'note')
      expect(page.search_by '[class=note]').to be_empty
    end
    it 'removes classes where values begin with specified patterns' do
      cleaner.remove_attribute_with_value(page, 'class', '^=TableStyle-')
      expect(page.search_by '[class^=TableStyle-]').to be_empty
    end
  end
end
