declare
bl_chars constant varchar(3) = ' ' || chr(10) || chr(13);
-- SQLINES LICENSE FOR EVALUATION USE ONLY
create function taxamatch1_reduce_spaces (str varchar(2000) :=null) returns varchar(2000) as $$
 declare
  temp varchar(32767) = '';
begin
  temp := rtrim(ltrim(str));
  while temp like '%  %' loop
    temp := replace(temp,'  ',' ');
  end loop;
  return temp;
end;
$$ language plpgsql;
-- SQLINES LICENSE FOR EVALUATION USE ONLY
create function taxamatch1_normalize (str varchar(4000) :=null) returns varchar(4000) as $$
 declare
begin
  temp varchar(32767) = '';
  first_str_part varchar(500);
  second_str_part varchar(500);
  temp_genus varchar(100) = '';
  temp_species varchar(100) = '';
  temp_genus_species varchar(200) = '';
  temp_authority varchar(300) = '';
  -- SQLINES LICENSE FOR EVALUATION USE ONLY
create or replace   function taxamatch1_good_chars (str varchar(4000) := null) returns varchar(4000) as $$
 declare
begin
    result       varchar(32767) = '';
    a_char       varchar(1);
    -- SQLINES LICENSE FOR EVALUATION USE ONLY
create or replace     function taxamatch1_char_test(a_char varchar(4000)) returns varchar(4000) as $$
      begin
      if (ascii(a_char) between 65 and 90) or cast(ascii(a_char) as int) = 32 or cast(ascii(a_char) as int) = 46 then
        return a_char;
      else
        return null;
      end if;
    end;
$$ language plpgsql;
END;
$$ language plpgsql;
END;
$$ language plpgsql;
  begin
    if str is null then
       return null;
    else
      for i in 1..length(str) loop
        a_char := substr(str, i, 1);
        result := result||char_test(a_char);
      end loop;
      return result;
    end if;
  good_chars;
begin
  if str is null or str = '' or ltrim(rtrim(str, bl_chars),bl_chars) is null then
    return '';
  else
    temp := (ltrim(rtrim(str, bl_chars),bl_chars));
  end if;
  if temp is null or temp = '' then
    return '';
  else
    if temp like '%'||'&'||'amp;%' then
      temp := replace(temp,'%'||'&'||'amp;%','&');
    end if;
    if temp like '%'||'&'||'AMP;%' then
     temp := replace(temp,'%'||'&'||'AMP;%','&');
    end if;
    if temp like '%<%>%' then
      first_str_part := null;
      second_str_part := null;
      while temp like '%<%>%' loop
        first_str_part := substr(temp,1,position('<' IN temp)-1);
        second_str_part := substr(temp,position('>' IN temp)+1);
        temp := replace(first_str_part||' '||second_str_part,'  ',' ');
      end loop;
    end if;
    if temp like '% (%)%' and position('(' IN temp) = position(' ' IN temp)+1 then
      first_str_part := substr(temp,1,position(' ' IN temp)-1);
      second_str_part := ltrim(substr(temp,position(')' IN temp)+1));
      temp := first_str_part||' '||second_str_part;
    end if;
    if temp like '% [%]%' and position('[' IN temp) = position(' ' IN temp)+1 then
      first_str_part := substr(temp,1,position(' ' IN temp)-1);
      second_str_part := ltrim(substr(temp,position(']' IN temp)+1));
      temp := first_str_part||' '||second_str_part;
    end if;
    if temp like '% cf %' then
      temp := replace(temp,' cf ',' ');
    end if;
    if temp like '% cf. %' then
      temp := replace(temp,' cf. ',' ');
    end if;
    if temp like '% near %' then
      temp := replace(temp,' near ',' ');
    end if;
    if temp like '% aff. %' then
      temp := replace(temp,' aff. ',' ');
    end if;
    if temp like '% sp.%' then
      temp := replace(temp,' sp.',' ');
    end if;
    if temp like '% spp.%' then
      temp := replace(temp,' spp.',' ');
    end if;
    if temp like '% spp %' then
      temp := replace(temp,' spp ',' ');
    end if;
    temp := reduce_spaces(temp);
    if temp like '% %' then
      temp_genus := substr(temp,1,position(' ' IN temp)-1);
      temp := substr(temp,position(' ' IN temp)+1);
    elsif temp not like '% %' and length(temp) >0 then
      temp_genus := temp;
      temp := '';
    end if;
    if temp like '% %' then
      temp_species := substr(temp,1,position(' ' IN temp)-1);
      temp_authority := substr(temp,position(' ' IN temp)+1);
    elsif temp not like '% %' and length(temp) >0 then
      temp_species := temp;
    end if;
    temp_genus_species := upper(rtrim(temp_genus||' '||temp_species));
    temp_genus_species := translate(temp_genus_species,'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÄËÏÖÜÃÑÕÅÇØ',
      'AEIOUAEIOUAEIOUAEIOUANOACO');
    if temp_genus_species like '%Æ%' then
      temp_genus_species := replace(temp_genus_species,'Æ','AE');
    end if;
    if temp_genus_species like '%'||chr(140)||'%' then
      temp_genus_species := replace(temp_genus_species,chr(140),'OE');
    end if;
    temp_genus_species := ltrim(rtrim(good_chars(temp_genus_species)));
    temp_genus_species := reduce_spaces(temp_genus_species);
    return rtrim(temp_genus_species||' '||temp_authority);
  end if;
end normalize;
-- SQLINES LICENSE FOR EVALUATION USE ONLY
create or replace function near_match(str varchar(4000) :=null, word_type varchar(4000) :=null) returns varchar(4000) as $$
 declare
  temp varchar(32767) = '';
  this_word varchar(200);
  word_no integer = 1;
  result varchar(32767) = '';
  -- SQLINES LICENSE FOR EVALUATION USE ONLY
  function treat_word(str2 varchar(4000) :=null, strip_endings varchar(4000) :=null) returns varchar(4000) as $$
 declare
    temp2 varchar(32767) = '';
    start_letter varchar(1) = '';
    l smallint;
    next_char varchar(1) = '';
    result2 varchar(32767) = '';
    begin
      if str2 is null or str2 = '' or ltrim(rtrim(str2, bl_chars),bl_chars) is null then
        return '';
      else
      temp2 := normalize(str2);
      if temp2 like 'AE%' then
        temp2 := 'E'||substr(temp2,3);
      elsif temp2 like 'CN%' then
        temp2 := 'N'||substr(temp2,3);
      elsif temp2 like 'CT%' then
        temp2 := 'T'||substr(temp2,3);
      elsif temp2 like 'CZ%' then
        temp2 := 'C'||substr(temp2,3);
      elsif temp2 like 'DJ%' then
        temp2 := 'J'||substr(temp2,3);
      elsif temp2 like 'EA%' then
        temp2 := 'E'||substr(temp2,3);
      elsif temp2 like 'EU%' then
        temp2 := 'U'||substr(temp2,3);
      elsif temp2 like 'GN%' then
        temp2 := 'N'||substr(temp2,3);
      elsif temp2 like 'KN%' then
        temp2 := 'N'||substr(temp2,3);
      elsif temp2 like 'MC%' then
        temp2 := 'MAC'||substr(temp2,3);
      elsif temp2 like 'MN%' then
        temp2 := 'N'||substr(temp2,3);
      elsif temp2 like 'OE%' then
        temp2 := 'E'||substr(temp2,3);
      elsif temp2 like 'QU%' then
        temp2 := 'Q'||substr(temp2,3);
      elsif temp2 like 'PS%' then
        temp2 := 'S'||substr(temp2,3);
      elsif temp2 like 'PT%' then
        temp2 := 'T'||substr(temp2,3);
      elsif temp2 like 'TS%' then
        temp2 := 'S'||substr(temp2,3);
      elsif temp2 like 'WR%' then
        temp2 := 'R'||substr(temp2,3);
      elsif temp2 like 'X%' then
        temp2 := 'Z'||substr(temp2,2);
      end if;
      start_letter :=substr(temp2,1,1);
      temp2 := substr(temp2,2);
      temp2 := replace(temp2, 'AE', 'I');
      temp2 := replace(temp2, 'IA', 'A');
      temp2 := replace(temp2, 'OE', 'I');
      temp2 := replace(temp2, 'OI', 'A');
      temp2 := replace(temp2, 'SC', 'S');
      temp2 := translate(temp2, 'EOUYKZH', 'IAIICS');
      temp2 := start_letter||temp2;
      l := length(temp2);
      for i in 1..l loop
        next_char := substr(temp2, i, 1);
        if i = 1 then
          result2 := next_char;
        elsif next_char = substr(result2,-1) then
          null;
        else
          result2 := result2||next_char;
        end if;
      end loop;
      if length(result2) >4 and strip_endings ='Y' then
      result2 := result2||' ';
      if result2 like '%IS %' then
        result2 := replace(result2, 'IS ','A ');
      end if;
      if result2 like '%IM %' then
        result2 := replace(result2, 'IM ','A ');
      end if;
      if result2 like '%AS %' then
        result2 := replace(result2, 'AS ','A ');
      end if;
      result2 := rtrim(result2);
      end if;
      return result2;
    end if;
  end;
$$ LANGUAGE plpgsql;
begin
   if str is null or str = '' or ltrim(rtrim(str, bl_chars),bl_chars) is null then
      return '';
    else
      temp := upper(str);
    if word_type = 'genus_only' then
      result := treat_word(temp);
    elsif word_type = 'epithet_only' then
      result := treat_word(temp, 'Y');
    else
      temp := temp||' ';
      while length(temp) >1 loop
        this_word := substr(temp,1,position(' ' IN temp)-1);
        if word_no = 1 then
          result := result||' '||treat_word(this_word);
        else
          result := result||' '||treat_word(this_word,'Y');
        end if;
        temp := substr(temp,position(' ' IN temp)+1);
        word_no := word_no +1;
      end loop;
    end if;
    return ltrim(result);
  end if;
end;
$$ language plpgsql;
-- SQLINES LICENSE FOR EVALUATION USE ONLY
CREATE OR REPLACE FUNCTION mdld
  (p_str1              VARCHAR(4000) DEFAULT NULL,
   p_str2              VARCHAR(4000) DEFAULT NULL,
   p_block_limit       INT   DEFAULT NULL)
  RETURNS INT
AS $$
DECLARE
  v_str1_length        INTEGER = COALESCE (LENGTH (p_str1), 0);
  v_str2_length        INTEGER = COALESCE (LENGTH (p_str2), 0);
  v_temp_str1          VARCHAR (32767);
  v_temp_str2          VARCHAR (32767);
  v_my_columns         myarray;
  v_empty_column       mytabtype;
  v_this_cost          INTEGER = 0;
  v_temp_block_length  INTEGER;
BEGIN
  IF p_str2 = p_str1 THEN
    RETURN 0;
  ELSIF v_str1_length = 0 OR v_str2_length = 0 THEN
    RETURN GREATEST (v_str1_length, v_str2_length);
  ELSIF v_str1_length = 1 AND v_str2_length = 1 AND p_str2 != p_str1 THEN
    RETURN 1;
  ELSE
    v_temp_str1 := p_str1;
    v_temp_str2 := p_str2;
    WHILE SUBSTR (v_temp_str1, 1, 1) = SUBSTR (v_temp_str2, 1, 1) LOOP
       v_temp_str1 := SUBSTR (v_temp_str1, 2);
       v_temp_str2 := SUBSTR (v_temp_str2, 2);
    END LOOP;
    WHILE SUBSTR (v_temp_str1, -1, 1) = SUBSTR (v_temp_str2, -1, 1) LOOP
       v_temp_str1 := SUBSTR (v_temp_str1, 1, LENGTH (v_temp_str1) - 1);
       v_temp_str2 := SUBSTR (v_temp_str2, 1, LENGTH (v_temp_str2) - 1);
    END LOOP;
    v_str1_length := COALESCE (LENGTH (v_temp_str1), 0);
    v_str2_length := COALESCE (LENGTH (v_temp_str2), 0);
    IF v_str1_length = 0 OR v_str2_length = 0 THEN
      RETURN GREATEST (v_str1_length, v_str2_length);
    ELSIF v_str1_length = 1 AND v_str2_length = 1 AND p_str2 != p_str1 THEN
      RETURN 1;
    ELSE
      FOR s in 0 .. v_str1_length LOOP
        v_my_columns (s) := v_empty_column;
      END LOOP;
      FOR t in 0 .. v_str2_length LOOP
        v_my_columns (0) (t) := t;
      END LOOP;
      FOR s in 1 .. v_str1_length LOOP
        v_my_columns (s) (0) := s  ;
        FOR t in 1 .. v_str2_length LOOP
          IF SUBSTR (v_temp_str1, s, 1) = SUBSTR (v_temp_str2, t, 1) THEN
            v_this_cost := 0;
          ELSE
            v_this_cost := 1;
          END IF;
          v_temp_block_length := LEAST ( (v_str1_length / 2), (v_str2_length / 2), COALESCE (p_block_limit, 1));
          WHILE v_temp_block_length >= 1 LOOP
            IF s >= (v_temp_block_length * 2) AND
               t >= (v_temp_block_length * 2) AND
               SUBSTR (v_temp_str1, s - ( (v_temp_block_length * 2) - 1), v_temp_block_length) =
                 SUBSTR (v_temp_str2, t - (v_temp_block_length - 1), v_temp_block_length) AND
               SUBSTR (v_temp_str1, s - (v_temp_block_length - 1), v_temp_block_length) =
                 SUBSTR (v_temp_str2, t - ( (v_temp_block_length * 2) - 1), v_temp_block_length) THEN
               v_my_columns (s) (t) := LEAST
                                         (v_my_columns (s) (t - 1) + 1,
                                          v_my_columns (s - 1) (t) + 1,
                                          (v_my_columns (s - (v_temp_block_length * 2)) (t - (v_temp_block_length * 2))
                                           + v_this_cost + (v_temp_block_length - 1)));
               v_temp_block_length := 0;
            ELSIF v_temp_block_length = 1 THEN
              v_my_columns (s) (t) := LEAST (v_my_columns (s) (t - 1) + 1,
                                             v_my_columns (s - 1) (t) + 1,
                                             v_my_columns (s - 1) (t - 1) + v_this_cost);
            END IF;
            v_temp_block_length := v_temp_block_length - 1;
          END LOOP;
        END LOOP;
      END LOOP;
    END IF;
    RETURN v_my_columns (v_str1_length) (v_str2_length);
  END IF;
END;
$$ LANGUAGE plpgsql;
-- SQLINES LICENSE FOR EVALUATION USE ONLY
create or replace function ngram (source_string varchar(2000) := null, target_string varchar(2000) := null, n_used integer := 1) returns int
as $$
declare
this_source_string varchar(32767);
this_target_string varchar(32767);
this_ngram varchar(100);
source_ngram_string varchar(32767);
target_ngram_string varchar(32767);
temp_number integer = null;
padding varchar(10) = null;
match_count integer = 0;
result int;
begin
  temp_number := n_used;
  while temp_number >1 loop
    padding := padding||' ';
    temp_number := temp_number -1;
  end loop;
  this_source_string := padding||source_string||padding;
  this_target_string := padding||target_string||padding;
  while length(this_source_string) >=n_used loop
    this_ngram := substr(this_source_string,1,n_used);
    if source_ngram_string like '%'||this_ngram||'(8)%' then
      source_ngram_string := source_ngram_string||this_ngram||'(9)';
    elsif source_ngram_string like '%'||this_ngram||'(7)%' then
      source_ngram_string := source_ngram_string||this_ngram||'(8)';
    elsif source_ngram_string like '%'||this_ngram||'(6)%' then
      source_ngram_string := source_ngram_string||this_ngram||'(7)';
    elsif source_ngram_string like '%'||this_ngram||'(5)%' then
      source_ngram_string := source_ngram_string||this_ngram||'(6)';
    elsif source_ngram_string like '%'||this_ngram||'(4)%' then
      source_ngram_string := source_ngram_string||this_ngram||'(5)';
    elsif source_ngram_string like '%'||this_ngram||'(3)%' then
      source_ngram_string := source_ngram_string||this_ngram||'(4)';
    elsif source_ngram_string like '%'||this_ngram||'(2)%' then
      source_ngram_string := source_ngram_string||this_ngram||'(3)';
    elsif source_ngram_string like '%'||this_ngram||'(1)%' then
      source_ngram_string := source_ngram_string||this_ngram||'(2)';
    else
      source_ngram_string := source_ngram_string||this_ngram||'(1)';
    end if;
    this_source_string := substr(this_source_string, 2);
  end loop;
  while length(this_target_string) >=n_used loop
    this_ngram := substr(this_target_string,1,n_used);
    if target_ngram_string like '%'||this_ngram||'(8)%' then
      target_ngram_string := target_ngram_string||this_ngram||'(9)';
    elsif target_ngram_string like '%'||this_ngram||'(7)%' then
      target_ngram_string := target_ngram_string||this_ngram||'(8)';
    elsif target_ngram_string like '%'||this_ngram||'(6)%' then
      target_ngram_string := target_ngram_string||this_ngram||'(7)';
    elsif target_ngram_string like '%'||this_ngram||'(5)%' then
      target_ngram_string := target_ngram_string||this_ngram||'(6)';
    elsif target_ngram_string like '%'||this_ngram||'(4)%' then
      target_ngram_string := target_ngram_string||this_ngram||'(5)';
    elsif target_ngram_string like '%'||this_ngram||'(3)%' then
      target_ngram_string := target_ngram_string||this_ngram||'(4)';
    elsif target_ngram_string like '%'||this_ngram||'(2)%' then
      target_ngram_string := target_ngram_string||this_ngram||'(3)';
    elsif target_ngram_string like '%'||this_ngram||'(1)%' then
      target_ngram_string := target_ngram_string||this_ngram||'(2)';
    else
      target_ngram_string := target_ngram_string||this_ngram||'(1)';
    end if;
    this_target_string := substr(this_target_string, 2);
  end loop;

  while length(source_ngram_string) >1 loop
    this_ngram := substr(source_ngram_string,1,n_used+3);
    if target_ngram_string like '%'||this_ngram||'%' then
      match_count := match_count+1;
    end if;
    source_ngram_string := substr(source_ngram_string,n_used+4);
  end loop;
  result := round((2*match_count)/(length(target_string)+length(source_string)+(n_used-1)+(n_used-1)),4);
  return result;
end;
$$ language plpgsql;
-- SQLINES LICENSE FOR EVALUATION USE ONLY
create or replace function normalize_auth (str varchar(2000) :=null) returns varchar(2000) as $$
 declare
   temp varchar(32767) = '';
   this_word varchar(50) = '';
   elapsed_chars varchar(32767) = '';
   this_auth_full varchar(200) = null;
 begin
  if str is null or str = '' or ltrim(rtrim(str, bl_chars),bl_chars) is null then
    return '';
  else
    temp := ltrim(rtrim(str, bl_chars),bl_chars);
  end if;
  if temp is null or temp = '' then
    return '';
  else
    if temp = 'L.' then
      temp := 'Linnaeus';
    elsif temp like '(L.)%' then
      temp := '(Linnaeus)'||substr(temp,5);
    elsif temp like 'L., 1%' or temp like 'L. 1%' then
      temp := 'Linnaeus'||substr(temp,3);
    elsif temp like '(L., 1%' or temp like '(L. 1%' then
      temp := '(Linnaeus'||substr(temp,4);
    elsif replace(temp,'é','e') = 'Linne' then
      temp := 'Linnaeus';
    elsif replace(temp,'é','e') like '(Linne)%' then
      temp := '(Linnaeus)'||substr(temp,8);
    elsif (replace(temp,'é','e') like 'Linne, 1%' or replace(temp,'é','e') like 'Linne 1%') then
      temp := 'Linnaeus'||substr(temp,6);
    elsif (replace(temp,'é','e') like '(Linne, 1%' or replace(temp,'é','e') like '(Linne 1%') then
      temp := '(Linnaeus'||substr(temp,7);
    elsif temp = 'DC.' or temp = '(DC.)' then
      temp := replace(temp, 'DC.', 'de Candolle');
    elsif temp = 'D.C.' or temp = '(D.C.)' then
      temp := replace(temp, 'D.C.', 'de Candolle');
    end if;
    temp := rtrim(replace(temp,'.','. '));
    if temp like '% et al%' then
      temp := replace(temp,' et al','zzzzz');
    end if;
    temp := replace(temp,' et ',' '||'&'||' ');
    temp := replace(temp,' and ',' '||'&'||' ');
    if temp like '%zzzzz%' then
      temp := replace(temp,'zzzzz',' et al');
    end if;
    if temp like '%, 17%' then
      temp := replace(temp,', 17',' 17');
    end if;
    if temp like '%, 18%' then
      temp := replace(temp,', 18',' 18');
    end if;
    if temp like '%, 19%' then
      temp := replace(temp,', 19',' 19');
    end if;
    if temp like '%, 20%' then
      temp := replace(temp,', 20',' 20');
    end if;
    if temp like '%  %' then
      temp := reduce_spaces(temp);
    end if;
    if temp like '% -%' then
      temp := replace(temp, ' -','-');
    end if;
    temp := temp||' ';
    while length(temp) > 1 loop
      this_word := substr(temp,1,position(' ' IN temp)-1);
      temp := substr(temp,position(' ' IN temp)+1);
      if this_word like '(%' then
        elapsed_chars := elapsed_chars||'(';
        this_word := substr(this_word,2);
      end if;
      if this_word like '%.' and length(this_word) >2 then
        begin
          -- SQLINES LICENSE FOR EVALUATION USE ONLY
          select auth_full
          into this_auth_full
          from auth_abbrev_test1
          where auth_abbr = this_word
          and auth_full != '-'
          and rownum=1;
        exception
          when no_data_found then null;
        end;
        if this_auth_full is not null then
          this_word := this_auth_full;
          this_auth_full := null;
        end if;
      end if;
      elapsed_chars := elapsed_chars||this_word||' ';
    end loop;
    if elapsed_chars like '% )%' then
      elapsed_chars := replace(elapsed_chars,' )',')');
    end if;
    return upper(ltrim(rtrim(elapsed_chars)));
  end if;
end;
$$ language plpgsql;
-- SQLINES LICENSE FOR EVALUATION USE ONLY
create or replace function compare_auth(auth1 varchar(2000) := null, auth2 varchar(2000) := null) returns int as $$
 declare
new_auth1 varchar(500);
new_auth2 varchar(500);
new_auth1b varchar(500);
new_auth2b varchar(500);
temp_auth_match1 int;
temp_auth_match2 int;
this_auth_match int;
auth1_has_date varchar(1) = 'N';
auth2_has_date varchar(1) = 'N';
begin
  if auth1 is null or auth2 is null then
    return null;
  else
    new_auth1 := normalize_auth(auth1);
    new_auth2 := normalize_auth(auth2);
    if new_auth1 = new_auth2 then
      this_auth_match := 1;
    else
      if substr(new_auth1,-4,1) between '0' and '9' and
        substr(new_auth1,-3,1) between '0' and '9' and
        substr(new_auth1,-2,1) between '0' and '9' then      
        auth1_has_date := 'Y';
      end if;
      if substr(new_auth2,-4,1) between '0' and '9' and
        substr(new_auth2,-3,1) between '0' and '9' and
        substr(new_auth2,-2,1) between '0' and '9' then
        auth2_has_date := 'Y';
      end if;
      if auth1_has_date = 'Y' and auth2_has_date = 'N' then
        if new_auth1 like '%)' then
          new_auth1 := rtrim(substr(new_auth1,1, length(new_auth1)-4))||')';
        else
          new_auth1 := rtrim(substr(new_auth1,1, length(new_auth1)-3));
        end if;
      elsif auth2_has_date = 'Y' and auth1_has_date = 'N' then			
        if new_auth2 like '%)' then
          new_auth2 := rtrim(substr(new_auth2,1, length(new_auth2)-4))||')';
        else
          new_auth2 := rtrim(substr(new_auth2,1, length(new_auth2)-3));
        end if;
      end if;
      new_auth1b := translate(new_auth1,'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÄËÏÖÜÃÑÕÅÇØ',
          'AEIOUAEIOUAEIOUAEIOUANOACO');
      new_auth2b := translate(new_auth2,'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÄËÏÖÜÃÑÕÅÇØ',
          'AEIOUAEIOUAEIOUAEIOUANOACO');
      temp_auth_match1 := ((2 * ngram(new_auth1,new_auth2,2))
        + ngram(new_auth1,new_auth2,3))/3;
      temp_auth_match2 := ((2 * ngram(new_auth1b,new_auth2b,2))
        + ngram(new_auth1b,new_auth2b,3))/3;
      this_auth_match := (temp_auth_match1 + temp_auth_match2) /2;
    end if;
    return round(this_auth_match,4);
  end if;
end;
$$ language plpgsql;
-- SQLINES LICENSE FOR EVALUATION USE ONLY
create or replace procedure taxamatch (searchtxt varchar(2000) :=null, search_mode varchar(4000) := 'normal', debug varchar(4000) := null)
as $$
declare
text_str varchar(32767);
this_search_genus varchar(50);
this_search_species varchar(50);
this_authority varchar(200);
this_near_match_genus varchar(50);
this_genus_start varchar(3);
this_genus_end varchar(3);
this_genus_length integer;
this_near_match_species varchar(50);
this_species_length integer;
genera_tested integer =0; 
species_tested integer =0;
gen_phonetic_flag varchar(1) = null;
sp_phonetic_flag varchar(1) = null;
temp_genus_ED integer;
temp_species_ED integer;
temp_genus_id varchar(15) = null;
temp_authority varchar(200);
auth_similarity int;
species_found varchar(1) = null;
temp_species_count integer;
err_msg varchar(50) = null;
 genus_cur cursor  for 
  select distinct A.genus_id, A.genus, A.near_match_genus, A.search_genus_name
  from genlist_test1 A, splist_test1 B
  where
    A.near_match_genus = this_near_match_genus
    or
    (
     (search_mode is null or (search_mode is not null and search_mode != 'rapid'))
      and
      A.gen_length between (this_genus_length-2) and (this_genus_length+2)
      and
      (
       (least(this_genus_length, A.gen_length) <5 and (A.search_genus_name like substr(this_genus_start,1,1)||'%' or
         A.search_genus_name like '%'||substr(this_genus_end,-1,1)))
       or
       (least(this_genus_length, A.gen_length) = 5 and (A.search_genus_name like substr(this_genus_start,1,2)||'%' or
         A.search_genus_name like '%'||substr(this_genus_end,-3,3)))
       or
       (least(this_genus_length, A.gen_length) >5 and (A.search_genus_name like this_genus_start||'%' or
         A.search_genus_name like '%'||this_genus_end))
      )
     )
    or
    (this_near_match_species is not null
    and A.gen_length between (this_genus_length-3) and (this_genus_length+3)
    and B.near_match_species = this_near_match_species
    and A.genus_id = B.genus_id)
  group by A.genus_id, A.genus, A.near_match_genus, A.search_genus_name
  order by A.genus;
 species_cur cursor(gen_id varchar) for
  select distinct A.species_id, A.species, A.search_species_name, A.near_match_species, B.near_match_genus||' '||
    A.near_match_species near_match_gen_sp, B.genus||' '||A.species genus_species
  from splist_test1 A, genlist_test1 B
  where A.genus_id = gen_id
  and B.genus_id = gen_id
  and sp_length between (this_species_length-4) and (this_species_length+4)
  group by A.species_id, A.species, A.search_species_name, A.near_match_species, B.near_match_genus||' '||
    A.near_match_species, B.genus||' '||A.species
  order by A.species;
 genus_result_cur cursor(this_ed varchar := null
$$ language plpgsql;) is
  -- SQLINES LICENSE FOR EVALUATION USE ONLY
  select distinct genus_id, genus, genus_ed, phonetic_flag
  from genus_id_matches
  where this_ed is null or
  (this_ed = '0' and genus_ed = 0) or
  (this_ed = 'P' and genus_ed >0 and phonetic_flag = 'Y') or
  (this_ed != 'P' and phonetic_flag is null and cast(this_ed as float) >0 and
    genus_ed = cast(this_ed as float))
  group by genus_id, genus, genus_ed, phonetic_flag
  order by genus_ed, genus;
cursor species_result_cur(this_ed varchar2 := null) is 
  -- SQLINES LICENSE FOR EVALUATION USE ONLY
  select distinct species_id, genus_species, genus_ed, species_ed, gen_sp_ed, phonetic_flag
  from species_id_matches
  where this_ed is null or
  (this_ed = '0' and gen_sp_ed = 0) or
  (this_ed = 'P' and gen_sp_ed >0 and phonetic_flag = 'Y') or
  (this_ed != 'P' and phonetic_flag is null and cast(this_ed as float) >0 and
    gen_sp_ed = cast(this_ed as float))
  group by species_id, genus_species, genus_ed, species_ed, gen_sp_ed, phonetic_flag
  order by species_ed, genus_ed, genus_species;
begin
    if searchtxt like '%+%' then
      text_str := replace(searchtxt,'+',' ');
    else
      text_str := searchtxt;
    end if;
    if text_str is null or text_str = '' or ltrim(rtrim(text_str, bl_chars),bl_chars) is null then
      err_msg := 'No or blank input string supplied';
      goto exit_sub;
    end if;
    text_str := normalize(text_str);
    if text_str like '%'||' '||'%' then
      this_search_genus := substr(text_str,1,position(' ' IN text_str)-1);
      text_str := rtrim(substr(text_str,position(' ' IN text_str)+1));
    else
      this_search_genus := text_str;
      text_str := null;
    end if;
    if text_str like '%'||' '||'%' then
      this_search_species := substr(text_str,1,position(' ' IN text_str)-1);
      this_authority := rtrim(substr(text_str,position(' ' IN text_str)+1));
    else
      this_search_species := text_str;
    end if;
    this_near_match_genus := near_match(this_search_genus);
    this_genus_start := substr(this_search_genus,1,3);
    this_genus_end := substr(this_search_genus,-3,3);
    this_genus_length := length(this_search_genus);
    if this_search_species is not null then
      this_near_match_species := near_match(this_search_species, 'epithet_only');
      this_species_length := length(this_search_species);
    end if;
    for drec in genus_cur loop 
      genera_tested := genera_tested +1;
      temp_genus_ED := mdld(drec.search_genus_name,this_search_genus,2);
      if (temp_genus_ED <= 3 and
          least(length(drec.search_genus_name),this_genus_length) > (temp_genus_ED*2) and
          (temp_genus_ED <2 or substr(drec.search_genus_name,1,1) = substr(this_search_genus,1,1))
         )
      or
         drec.near_match_genus = this_near_match_genus
      then
        if drec.near_match_genus = this_near_match_genus then
          gen_phonetic_flag := 'Y';
        else
          gen_phonetic_flag := null;
        end if;
        begin
          -- SQLINES LICENSE FOR EVALUATION USE ONLY
          insert into genus_id_matches(genus_id, genus, genus_ed, phonetic_flag)
            values (drec.genus_id, drec.genus, temp_genus_ED, gen_phonetic_flag);
        end;
        if this_search_species is not null then
          for drec1 in species_cur(drec.genus_id) loop
            species_tested := species_tested +1;
            temp_species_ED := mdld(drec1.search_species_name,this_search_species,4);
            if drec1.near_match_species = this_near_match_species
              or
              (temp_genus_ED + temp_species_ED <=4 and
               (
                temp_species_ED <= 4 and
                least(length(drec1.species),this_species_length) >= (temp_species_ED*2) and
                (temp_species_ED <2 or drec1.search_species_name like substr(this_search_species,1,1)||'%')
                 and
                (temp_species_ED <4 or drec1.search_species_name like substr(this_search_species,1,3)||'%') and
                (temp_genus_ED+temp_species_ED <=4)
               )
              )
              then
              if drec.near_match_genus = this_near_match_genus and
                drec1.near_match_species = this_near_match_species then
                sp_phonetic_flag := 'Y';
              else
                sp_phonetic_flag := null;
              end if;
              begin
              -- SQLINES LICENSE FOR EVALUATION USE ONLY
              insert into species_id_matches(species_id, genus_species,
                genus_ed, species_ed, gen_sp_ed, phonetic_flag)
              values (drec1.species_id, drec1.genus_species,
                temp_genus_ED, temp_species_ED,
                temp_genus_ED+temp_species_ED, sp_phonetic_flag);
              end;
            end if;
          end loop;
        end if;
      end if;
    end loop;
    raise notice '%','---------';
    raise notice '%','** Input name: '||searchtxt||' **';
    raise notice '%','---------';
    raise notice '%','Genus exact matches:';
    for drec in genus_result_cur('0') loop
      begin
        -- SQLINES LICENSE FOR EVALUATION USE ONLY
        select authority
        into temp_authority
        from genlist_test1
        where genus_id = drec.genus_id;
      end;
      raise notice '%',' * '||drec.genus||' '||temp_authority||' (ID: '||drec.genus_id||')';
    end loop;
    raise notice '%','---------';
    raise notice '%','Genus phonetic matches:';
    for drec in genus_result_cur('P') loop
      begin
        -- SQLINES LICENSE FOR EVALUATION USE ONLY
        select authority
        into temp_authority
        from genlist_test1
        where genus_id = drec.genus_id;
      end;
      raise notice '%',' * '||drec.genus||' '||temp_authority||' (ID: '||drec.genus_id||')';
    end loop;
    raise notice '%','---------';
    raise notice '%','Other genus near matches:';
    for drec in genus_result_cur('1') loop
      begin
        -- SQLINES LICENSE FOR EVALUATION USE ONLY
        select authority
        into temp_authority
        from genlist_test1
        where genus_id = drec.genus_id;
      end;
      raise notice '%',' * '||drec.genus||' '||temp_authority||' (ID: '||drec.genus_id||')';
    end loop;
    for drec in genus_result_cur('2') loop
      begin
        -- SQLINES LICENSE FOR EVALUATION USE ONLY
        select authority
        into temp_authority
        from genlist_test1
        where genus_id = drec.genus_id;
      end;
      raise notice '%',' * '||drec.genus||' '||temp_authority||' (ID: '||drec.genus_id||')';
    end loop;
    for drec in genus_result_cur('3') loop
      begin
        -- SQLINES LICENSE FOR EVALUATION USE ONLY
        select authority
        into temp_authority
        from genlist_test1
        where genus_id = drec.genus_id;
      end;
      raise notice '%',' * '||drec.genus||' '||temp_authority||' (ID: '||drec.genus_id||')';
    end loop;
    if this_search_species is not null then
      raise notice '%','---------';
      raise notice '%','Species exact matches:';
      for drec in species_result_cur('0') loop
        begin
          -- SQLINES LICENSE FOR EVALUATION USE ONLY
          select authority
          into temp_authority
          from splist_test1
          where species_id = drec.species_id;
        end;
        if this_authority is not null then
          auth_similarity := compare_auth(this_authority, temp_authority);
          raise notice '%',' * '||drec.genus_species||' '||temp_authority||' (ID: '||drec.species_id||')' ||
          ' ED '||to_char(drec.genus_ed)||','||to_char(drec.species_ed)||' auth. similarity='||to_char(auth_similarity);
        else
          raise notice '%',' * '||drec.genus_species||' '||temp_authority||' (ID: '||drec.species_id||')' ||
          ' ED '||to_char(drec.genus_ed)||','||to_char(drec.species_ed);
        end if;
      end loop;
      raise notice '%','---------';
      raise notice '%','Species phonetic matches:';
      for drec in species_result_cur('P') loop
        species_found := 'Y';
        begin
          -- SQLINES LICENSE FOR EVALUATION USE ONLY
          select authority
          into temp_authority
          from splist_test1
          where species_id = drec.species_id;
        end;
        if this_authority is not null then
          auth_similarity := compare_auth(this_authority, temp_authority);
          raise notice '%',' * '||drec.genus_species||' '||temp_authority||' (ID: '||drec.species_id||')' ||
          ' ED '||to_char(drec.genus_ed)||','||to_char(drec.species_ed)||' auth. similarity='||to_char(auth_similarity);
        else
          raise notice '%',' * '||drec.genus_species||' '||temp_authority||' (ID: '||drec.species_id||')' ||
          ' ED '||to_char(drec.genus_ed)||','||to_char(drec.species_ed);
        end if;
      end loop;
      raise notice '%','---------';
      raise notice '%','Other species near matches:';
      for drec in species_result_cur('1') loop
        species_found := 'Y';
        begin
          -- SQLINES LICENSE FOR EVALUATION USE ONLY
          select authority
          into temp_authority
          from splist_test1
          where species_id = drec.species_id;
        end;
        if this_authority is not null then
          auth_similarity := compare_auth(this_authority, temp_authority);
          raise notice '%',' * '||drec.genus_species||' '||temp_authority||' (ID: '||drec.species_id||')' ||
          ' ED '||to_char(drec.genus_ed)||','||to_char(drec.species_ed)||' auth. similarity='||to_char(auth_similarity);
        else
          raise notice '%',' * '||drec.genus_species||' '||temp_authority||' (ID: '||drec.species_id||')' ||
          ' ED '||to_char(drec.genus_ed)||','||to_char(drec.species_ed);
        end if;
      end loop;
      for drec in species_result_cur('2') loop
        species_found := 'Y';
        begin
          -- SQLINES LICENSE FOR EVALUATION USE ONLY
          select authority
          into temp_authority
          from splist_test1
          where species_id = drec.species_id;
        end;
        if this_authority is not null then
          auth_similarity := compare_auth(this_authority, temp_authority);
          raise notice '%',' * '||drec.genus_species||' '||temp_authority||' (ID: '||drec.species_id||')' ||
          ' ED '||to_char(drec.genus_ed)||','||to_char(drec.species_ed)||' auth. similarity='||to_char(auth_similarity);
        else
          raise notice '%',' * '||drec.genus_species||' '||temp_authority||' (ID: '||drec.species_id||')' ||
          ' ED '||to_char(drec.genus_ed)||','||to_char(drec.species_ed);
        end if;
      end loop;
      if species_found = 'Y' then
        begin
          -- SQLINES LICENSE FOR EVALUATION USE ONLY
          select count(*)
          into temp_species_count
          from species_id_matches
          where phonetic_flag is null and gen_sp_ed = 3;
        end;
        if temp_species_count >0 and search_mode != 'no_shaping' then
          raise notice '%','---------';
          raise notice '%','(Additional ED 3 near matches are present, currently hidden by result shaping)';
        end if;
      end if;
      if temp_species_count >0 and search_mode = 'no_shaping' then
        for drec in species_result_cur('3') loop
          species_found := 'Y';
          begin
            -- SQLINES LICENSE FOR EVALUATION USE ONLY
            select authority
            into temp_authority
            from splist_test1
            where species_id = drec.species_id;
          end;
          if this_authority is not null then
            auth_similarity := compare_auth(this_authority, temp_authority);
            raise notice '%',' * '||drec.genus_species||' '||temp_authority||' (ID: '||drec.species_id||')' ||
            ' ED '||to_char(drec.genus_ed)||','||to_char(drec.species_ed)||' auth. similarity='||to_char(auth_similarity);
          else
            raise notice '%',' * '||drec.genus_species||' '||temp_authority||' (ID: '||drec.species_id||')' ||
            ' ED '||to_char(drec.genus_ed)||','||to_char(drec.species_ed);
          end if;
        end loop;
      end if;
      if species_found = 'Y' then
        begin
          -- SQLINES LICENSE FOR EVALUATION USE ONLY
          select count(*)
          into temp_species_count
          from species_id_matches
          where phonetic_flag is null and gen_sp_ed = 4;
        end;
        if temp_species_count >0  and search_mode != 'no_shaping' then
          raise notice '%','---------';
          raise notice '%','(Additional ED 4 near matches are present, currently hidden by result shaping)';
        end if;
      end if;
      if temp_species_count >0 and search_mode = 'no_shaping' then
        for drec in species_result_cur('4') loop
          species_found := 'Y';
          begin
            -- SQLINES LICENSE FOR EVALUATION USE ONLY
            select authority
            into temp_authority
            from splist_test1
            where species_id = drec.species_id;
          end;
          if this_authority is not null then
            auth_similarity := compare_auth(this_authority, temp_authority);
            raise notice '%',' * '||drec.genus_species||' '||temp_authority||' (ID: '||drec.species_id||')' ||
            ' ED '||to_char(drec.genus_ed)||','||to_char(drec.species_ed)||' auth. similarity='||to_char(auth_similarity);
          else
            raise notice '%',' * '||drec.genus_species||' '||temp_authority||' (ID: '||drec.species_id||')' ||
            ' ED '||to_char(drec.genus_ed)||','||to_char(drec.species_ed);
          end if;
        end loop;
      end if;
    end if; 
    if debug is not null then
      raise notice '%','---------';
      raise notice '%','##########';
      raise notice '%','---------';
      raise notice '%','DEBUG INFO';
      raise notice '%','searchtxt: '||searchtxt;
      raise notice '%','search_mode: '||search_mode;
      raise notice '%','debug: '||debug;
      raise notice '%','this_search_genus: '||this_search_genus;
      raise notice '%','this_search_species: '||this_search_species;
      raise notice '%','this_authority: '||this_authority;
      raise notice '%','this_near_match_genus: '||this_near_match_genus;
      raise notice '%','this_genus_start: '||this_genus_start;
      raise notice '%','this_genus_end: '||this_genus_end;
      raise notice '%','this_genus_length: '||to_char(this_genus_length);
      raise notice '%','this_near_match_species: '||this_near_match_species;
      raise notice '%','this_species_length: '||to_char(this_species_length);
      raise notice '%','No. of genera tested: '||to_char(genera_tested);
      raise notice '%','"GENUS ID MATCHES" TABLE CONTENT:';
      for drec in genus_result_cur loop
        raise notice '%','genus_id: '||drec.genus_id||', genus: '||drec.genus||
          ', genus_ed: '||drec.genus_ed||', phonetic_flag: '||drec.phonetic_flag;
      end loop;
      raise notice '%','No. of species tested: '||to_char(species_tested);
      raise notice '%','"SPECIES ID MATCHES" TABLE CONTENT:';
      for drec in species_result_cur loop
        raise notice '%','species_id: '||drec.species_id||', genus_species: '||drec.genus_species||
          ', genus_ed: '||drec.genus_ed||', species_ed: '||drec.species_ed||', gen_sp_ed: '||
          drec.gen_sp_ed||', phonetic_flag: '||drec.phonetic_flag;
      end loop;
    end if;  
    <<exit_sub>>
    if err_msg is not null then
      raise notice '%','ERROR: '||err_msg;
    end if;
    begin
      delete from genus_id_matches;
    end;
    begin
      delete from species_id_matches;
    end;
end;