package it.unica.diee.mdc.profiling;
import java.util.*; 

public class Permutations<T>
{

    public Collection<List<T>> permute(Collection<T> input) {
    {
         Collection<List<T>> output = new ArrayList<List<T>>();
           if (input.isEmpty()) {
                output.add(new ArrayList<T>());
                return output;
            }
            List<T> list = new ArrayList<T>(input);
            T head = list.get(0);
            List<T> rest = list.subList(1, list.size());
            for (List<T> permutations : permute(rest)) {
                List<List<T>> subLists = new ArrayList<List<T>>();
                for (int i = 0; i <= permutations.size(); i++) {
                    List<T> subList = new ArrayList<T>();
                    subList.addAll(permutations);
                    subList.add(i, head);
                    subLists.add(subList);
                }
                output.addAll(subLists);
            }
            return output;
        }
    }
} 