require 'nb_class/error/category_name_already_exists'
require 'nb_class/error/invalid_category_name'
require 'nb_class/phrase_array'
require 'nb_class/utils'

module NBClass
  class Classifier
    SMALL_PROBABILITY = 0.000001

    def initialize
      @category_examples = {}
      @occurrences = {}
      @global_occurrences = {}
      @probabilities = {}
      @global_probabilities = {}
      @category_occurrences = {}
      @total_elements = 0
      @total_phrases = 0;
    end

    def categories
      @category_examples.keys
    end

    def train
      @category_examples.keys.each do |category|
        @category_examples[category].each do |phrase|
          phrase.each do |word|
            count_element_occurrence_in_category(category,word)
            count_element_occurrence_in_global(word)
            @total_elements += 1
          end
          count_category_occurrence(category)
          @total_phrases += 1
        end
      end
    end

    def classify(elements)
      elements = Utils.break_phrase_in_word_array(elements)
      max_category = nil
      max_probability = 0.0
      @occurrences.keys.each do |key|
        probability = category_probability_given_elements(category: key,elements: elements)
        if probability > max_probability
          max_probability = probability
          max_category = key
        end
      end
      max_category
    end

    def element_occurrence(params)
      category = params[:category]
      element = params[:element]
      if category
        @occurrences[category][element]
      else
        @global_occurrences[element]
      end
    end

    def element_probability_given_category(params)
      category = params[:category]
      element  = params[:element]
      element_occurrence_in_category = @occurrences[category][element]
      total_elements_in_category = @occurrences[category].map{ |item| item[1] }.inject{ |sum, item| sum + item }
      unless element_occurrence_in_category.nil?
        element_occurrence_in_category.to_f / total_elements_in_category.to_f
      else
        SMALL_PROBABILITY
      end
    end

    def element_probability(element)
      element_occurrence = @global_occurrences[element]
      unless element_occurrence.nil?
        element_occurrence.to_f / @total_elements
      else
        SMALL_PROBABILITY
      end
    end

    def category_probability(category)
      @category_occurrences[category].to_f / @total_phrases.to_f
    end

    def category_probability_given_elements(params)
      category = params[:category]
      elements = params[:elements]
      probability = 1.0
      elements.each do |element|
        element_probability_given_category = element_probability_given_category(category: category, element: element)
        element_global_probability = element_probability(element)
        element_probability = element_probability_given_category / element_global_probability
        probability *= element_probability
      end
      category_probability = category_probability(category)
      probability *= category_probability
      probability
    end

    def method_missing(name, *args, &block)
      @category_examples[name] = PhraseArray.new
      define_singleton_method name do
        @category_examples[name]
      end
      public_send(name)
    end

    private

    def count_element_occurrence_in_category(category, element)
      unless @occurrences.has_key?(category)
        @occurrences[category] = {}
      end
      if !@occurrences[category].has_key?(element)
        @occurrences[category][element] = 1
      else
        @occurrences[category][element] += 1
      end
    end

    def count_element_occurrence_in_global(element)
      unless @global_occurrences.has_key?(element)
        @global_occurrences[element] = 1
      else
        @global_occurrences[element] += 1
      end
    end

    def count_category_occurrence(category)
      if @category_occurrences[category].nil?
        @category_occurrences[category] = 1
      else
        @category_occurrences[category] += 1
      end
    end
  end
end
